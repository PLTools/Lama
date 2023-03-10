//
// Created by Kirill Golubev on 08.03.2023.
//

#include <stdbool.h>
# include "../runtime/runtime.h"
# include "bytecommon.h"

int* stack_start = NULL;
int* stack_end = NULL;
#define  STACK_CAPACITY (1024 * 1024)

struct {
    int mem[STACK_CAPACITY];
    int *sp;
} stack;


int pop() {
    // fprintf(stderr, "\tpoping");
    if (stack.sp == stack_start) {
        fprintf(stderr, "\tempty stack!!\n");
        failure("Pop from empty stack\n");
    }
    stack.sp--;
    __gc_stack_top = stack.sp;
    int ret = *stack.sp;
    // fprintf(stderr, " %d\n", ret);
    return ret;
}

void push(int v) {
    // fprintf(stderr, "\tpushing %d\n", v);

    if (stack.sp == stack_end) {
        fprintf(stderr, "\tfull stack!!\n");
        failure("Stack overflow\n");
    }
    *stack.sp = v;
    stack.sp++;
    __gc_stack_top = stack.sp;
}



int make_hash (char *s) {
    char *p;
    int h = 0, limit = 0;

    p = s;

    while (*p && limit++ < 4) {
        char *q = chars;
        int pos = 0;

        for (; *q && *q != *p; q++, pos++);

        if (*q) h = (h << 6) | pos;
        else failure("tagHash: character not found: %c\n", *p);

        p++;
    }
    if (strcmp (s, de_hash (h)) != 0) {
        failure ("%s <-> %s\n", s, de_hash(h));
    }

    return BOX(h);
}

int check_tag (void *d, int t, int n) {
    data * r = TO_DATA(d);
    if (UNBOXED(d)) return BOX(0);

    return BOX(TAG(r->tag) == SEXP_TAG && TO_SEXP(d)->tag == t && LEN(r->tag) == n);
}

void* make_sexp (int n, int hash) {
    // printf("with hash %d", hash);
  int     i, ai;  
  sexp   *r;  
  data   *d;  
  r = (sexp*) malloc (sizeof(int) * (n + 2));
  d = &(r->contents);    
  d->tag = SEXP_TAG | (n << 3);

  for (i=n - 1; i>= 0; i--) {
    ((int*)d->contents)[i] = pop();
  }

  r->tag = hash;

    // printf("checking %d", d);
  return d->contents;
}

void* make_closure (int n, void *entry) {
  int     i, ai;
  data    *r; 

  r = (data*) malloc (sizeof(int) * (n+2));

  r->tag = CLOSURE_TAG | ((n + 1) << 3);
  ((void**) r->contents)[0] = entry;

  for (i = 0; i<n; i++) {
        ai = pop();
        ((int*)r->contents)[i+1] = ai;
        // printf("Closure %d\n", ai);
  }


  return r->contents;
}

void* make_string(void *p) {
    fprintf(stderr, "making string: %s\n", p);
    int   n = strlen (p);
    data *r = (data*) malloc (n + 1 + sizeof (int));
    r->tag = STRING_TAG | (n << 3);

    strncpy (r->contents, p, n + 1);

    fprintf(stderr, "allocated string: %s\n", r->contents);
    return r->contents;
}

void* make_array(int n) {
    int     i, ai; 
    data    *r; 
    r = (data*) malloc (sizeof(int) * (n+1));
    r->tag = ARRAY_TAG | (n << 3);

    for (i = n -1; i >=0; i--) {
        ((int*)r->contents)[i] = pop();
    }
    return r->contents;
}

void init_interpreter() {
    __init();
    stack.sp = stack.mem;
    stack_start = stack.sp;
    __gc_stack_bottom = stack.sp;
    stack_end = stack.sp + STACK_CAPACITY;
}

typedef struct Scope Scope;
struct Scope {
    char* origin_ip;
    Scope* outer;

    int* vars;
    int* args;
    int* acc;
};

int main(int argc, char*argv[]){
    
    init_interpreter();

    bytefile *bf = read_file(argv[1]);

    FILE* f = stderr;

    fprintf(f, "Entered main\n");

# define INT    (ip += sizeof (int), *(int*)(ip - sizeof (int)))
# define BYTE   *ip++
# define STRING get_string (bf, INT)
# define FAIL   failure ("ERROR: invalid opcode %d-%d\n", h, l)

    char *ops[] = {"+", "-", "*", "/", "%", "<", "<=", ">", ">=", "==", "!=", "&&", "!!"};
    char *pats[] = {"=str", "#string", "#array", "#sexp", "#ref", "#val", "#fun"};
    char *lds[] = {"LD", "LDA", "ST"};
    char *ip = bf->code_ptr;

    char* instr_repr[] = {"BinOP", "STOR", "LD", "LDA", "ST", "Control", "Pattern", "Builtin", 
     "No such intruction",
     "No such intruction",
     "No such intruction",
     "No such intruction",
     "No such intruction",
     "No such intruction",
     "No such intruction",
     "EOF"
     };

    Scope* cur_scope = NULL;

    do{
        char x = BYTE,
                h = (x & 0xF0) >> 4,
                l = x & 0x0F;

        // fprintf(stderr, "Processing %d: %s, %d\n", x, instr_repr[h], l);

        switch (h) {
            case 15: goto exit;
            case 0:{//BINOP
                int y = UNBOX(pop());
                int x = UNBOX(pop());
                int res = 0;
                switch(l-1) {
                    case 0:  res = x +  y; break;
                    case 1:  res = x -  y; break;
                    case 2:  res = x *  y; break;
                    case 3:  res = x /  y; break;
                    case 4:  res = x %  y; break;
                    case 5:  res = x <  y; break;
                    case 6:  res = x <= y; break;
                    case 7:  res = x >  y; break;
                    case 8:  res = x >= y; break;
                    case 9:  res = x == y; break;
                    case 10: res = x != y; break;
                    case 11: res = x && y; break;
                    case 12: res = x || y; break;
                } push(BOX(res)); break;}
        case 1: switch (l) { //CONTROL
                    int res;
                    case 0: push(BOX(INT));                                                         break;
                    case 1:{res = make_string(STRING);push(res);}                                   break;
                    case 2:{int hash = make_hash(STRING); push(make_sexp(INT, hash));}              break;
                    case 3: FAIL;
                    case 4: {int v = pop(); int i = pop(); int loc = pop(); push(Bsta(v, i, loc));} break;
                    case 5: ip = bf->code_ptr + INT;                                                break;
                    case 6:{
                        if (cur_scope->outer == NULL) return;
                        res = pop();
                        stack.sp = cur_scope->args;
                        ip = cur_scope->origin_ip;
                        cur_scope = cur_scope->outer;
                        push(res);
                        break;}
                    case  7: FAIL;
                    case  8: pop();                                             break;
                    case  9:{int v = pop(); push(v); push(v);}                  break;
                    case 10:{int a = pop();int b = pop(); push(b); push(a);}    break;
                    case 11:{int b = pop(); int a = pop(); push(Belem(a, b));}  break;
                    default: FAIL; } break;

        case 2: //LD
        case 3: //LDA
        case 4:{//ST
                int *p = 0;
                switch (l) {
                    case 0: p = bf->global_ptr  + INT;    break;
                    case 1: p = cur_scope->vars + INT;    break;
                    case 2: p = cur_scope->args + INT;    break;
                    case 3: p = *(cur_scope->acc  + INT); break;
                    default: FAIL;
                }
                switch(h){
                    case 2: {int value = *p; push(value);}          break; //LD
                    case 3:  push(p); push(p);                      break; //LDA
                    case 4: {int res = pop(); *p = res; push(res);} break; //ST
            }
            break;}

        case 5: switch (l) {
                    case 0: {int v = UNBOX(pop()); int dst = INT; if (!v)ip = bf->code_ptr + dst;} break;
                    case 1: {int v = UNBOX(pop()); int dst = INT; if ( v)ip = bf->code_ptr + dst;} break;
                    case 2: {
                        Scope* scope = malloc(sizeof(Scope));
                        scope->args = stack.sp;
                        stack.sp += INT + 1; 
                        scope->origin_ip = pop();
                        scope->vars = stack.sp;
                        scope->acc = scope->vars;
                        stack.sp += INT; 
                        scope->outer = cur_scope;
                        cur_scope = scope;
                        break;}
                    case 3:{
                        Scope* scope = malloc(sizeof(Scope));
                        int n = INT;
                        scope->args = stack.sp;
                        stack.sp += n + 2;
                        n = pop();
                        scope->origin_ip = pop();
                        stack.sp += 2;
                        scope->acc = stack.sp;
                        stack.sp += n;
                        scope->vars = stack.sp;
                        stack.sp += INT;
                        scope->outer = cur_scope;
                        cur_scope = scope;
                        break;}
                    case  4:{ //CLOSURE
                        int res = 0;
                        int pos = INT;
                        int n = INT;
                        for (int i = 0; i < n; i++) {
                            switch (BYTE) {
                                    case 0: res = *(bf->global_ptr + INT);        break;
                                    case 1: res = *(cur_scope->vars + INT);       break;
                                    case 2: res = *(cur_scope->args + INT);       break;
                                    case 3: res = *(int*)*(cur_scope->acc + INT); break;
                                    default: fprintf (f, "failed in closure construction: "); FAIL;
                                }
                            push(res);
                        } push(make_closure(n, pos)); 
                        break;}
                    case  5:{//CALLC
                        int n = INT;
                        data* d = TO_DATA(*(stack.sp - n - 1));
                        memmove(stack.sp - n - 1, stack.sp - n, n * sizeof(int));
                        stack.sp--;
                        int offset = *(int*)d->contents;
                        int accN = LEN(d->tag) - 1;
                        push(ip);
                        push(accN);
                        for (int i = accN - 1; i >= 0; i--) {
                            push(((int*)d->contents) + i + 1);
                        }
                        ip = bf->code_ptr + offset;
                        stack.sp -= accN+n+2;
                        break;}

                    case 6 :{ int v = INT; int n = INT; push(ip); push(0); 
                              ip = bf->code_ptr + v; stack.sp -= (n + 2);}                                   break;
                    case 7 :{ int v = make_hash(STRING); int n = INT; push(check_tag(pop(), v, n));}         break;
                    case 8 :{ int n = BOX(INT); push(Barray_patt(pop(), n));}                                break;
                    case 9 :{ int a = BOX(INT); int b = BOX(INT); Bmatch_failure(pop(), "", a, b);}          break;
                    case 10: INT;                                                                            break;
                    default: FAIL; }
            break;
        case 6:{
            int res;
            int a, b;
            switch (l) {
                case 0: a = pop(); b = pop(); res = Bstring_patt(a, b); break;
                case 1: res = Bstring_tag_patt(pop());                  break;
                case 2: res = Barray_tag_patt(pop());                   break;
                case 5: res = Bunboxed_patt(pop());                     break;
                case 6: res = Bclosure_tag_patt(pop());                 break;
                default: FAIL; } 
            push(res); break;}
        case 7:{ 
            int res;
            switch (l){
                case 0: res = Lread();             break;
                case 1: res = Lwrite(pop());       break;
                case 2: res = Llength(pop()); fprintf(stderr, "Got length: %d\n", res); break;
                case 3: res = Lstring(pop());      break;
                case 4: res = make_array(INT);     break;
                default: FAIL; }
            push(res); break;}
        default: FAIL;
    }

    }while(true);
exit:
    fprintf (f, "<exit>\n");
    return 0;
}