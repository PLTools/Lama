//
// Created by Kirill Golubev on 08.03.2023.
//

# include <stdbool.h>
# include "../runtime/runtime.h"
# include "bytecommon.h"

# include <stdexcept>
# include <array>
# include <functional>
# include <iostream>
# include <sstream>
# include <vector>

namespace interpreter{
    const size_t stack_capacity = 1024 * 1024;
    const std::array<std::function<int(int, int)>, 13> bops = {
        [](int x, int y) { return x +  y;},
        [](int x, int y) { return x -  y;},
        [](int x, int y) { return x *  y;},
        [](int x, int y) { return x /  y;},
        [](int x, int y) { return x %  y;},
        [](int x, int y) { return x <  y;},
        [](int x, int y) { return x <= y;},
        [](int x, int y) { return x >  y;},
        [](int x, int y) { return x >= y;},
        [](int x, int y) { return x == y;},
        [](int x, int y) { return x != y;},
        [](int x, int y) { return x && y;},
        [](int x, int y) { return x || y;}
    };
    //char *ops[] = {"+", "-", "*", "/", "%", "<", "<=", ">", ">=", "==", "!=", "&&", "!!"};
    const char* instr_repr[] = {
        "BinOP", "STOR", "LD", "LDA", "ST", "Control", "Pattern", "Builtin", 
        "No such intruction",
        "No such intruction",
        "No such intruction",
        "No such intruction",
        "No such intruction",
        "No such intruction",
        "No such intruction",
        "EOF"
    };

    const char* stor_repr[] = {
        "CONST", "STRING", "SEXP",
        "STI", "STA", "JMP", "END",
        "RET", "DROP", "DUP",
        "SWAP", "ELEM"
    };

    const char* control_repr[] = {
        "CJMPz", "CJMPnz", "BEGIN",
        "CBEGIN", "CLOSURE", "CALLC",
        "CALL", "TAG", "ARRAY", "FAIL",
        "LINE"
    };

    const char* patt_repr[] = {
        "=str", "#string", "#array",
        "#sexp", "#ref", "#val", "#fun"
    };

    const char *lds [] = {"LD", "LDA", "ST"};

    const char *builtins[] = {
        "read", "write", "length", "string", "array"
    };

    

    struct Scope {
        char* origin_ip;
        Scope* outer;
    
        int* vars;
        int* args;
        int* acc;

        std::string repr_scope(){
            std::stringstream ss;

            std::vector<int> sv;

            for(auto tmp = this; tmp != nullptr; tmp = tmp->outer){
                sv.push_back(((int)tmp) % 100);
            }
            std::reverse(sv.begin(), sv.end());
            for(auto i : sv){
                ss << i << "<-";
            }
            return ss.str();
        }
    };

     struct interpreter_fail : std::exception{

        char text[256];

        interpreter_fail(char l, char h){
            sprintf(text, "ERROR: invalid opcode %d-%d\n", h, l);
        }

        interpreter_fail(char const* fmt, ...){
            va_list ap;
            va_start(ap, fmt);
            vsnprintf(text, sizeof text, fmt, ap);
            va_end(ap);
        }

        char const* what() const throw() {return text;}
        
     };

    int* stack_start = nullptr;
    int* stack_end   = nullptr;

    class {
        struct {
            int mem[stack_capacity];
            int *sp;

            int pop() {
                if (sp == stack_start){
                    throw std::runtime_error("Pop from empty stack");
                }
                

                sp--;
                __gc_stack_top = (size_t)sp;
                int ret = *sp;

                // std::cerr << stack_repr() << std::endl;
                return ret;
            }

            void push(void* v){
                push((int)v);
            }

            void push(int v){
                if (sp == stack_end){
                    throw std::runtime_error("Push to full stack");
                }

                *sp = v;
                sp++;
                __gc_stack_top = (size_t)sp;

                // std::cerr << stack_repr() << std::endl;
            }

            std::string stack_repr(){
                std::stringstream ss;
                ss << "[";
                for (int* isp = mem; isp != sp; ++isp){
                    ss << UNBOX(*isp) << " ";
                }
                ss << "]";
                return ss.str();
            }
        } stack;

        bytefile* bf = nullptr;

        Scope* cur_scope = nullptr;
        char*  ip        = nullptr;

        FILE* log = nullptr;

        # define INT    (ip += sizeof (int), *(int*)(ip - sizeof (int)))
        # define BYTE   *ip++
        # define STRING get_string (bf, INT)
    public:
        auto& init(){
            __init();

            stack.sp = stack.mem;
            stack_start = stack.sp;
            __gc_stack_bottom = (size_t)stack.sp;
            stack_end = stack.sp + stack_capacity;

            return *this;
        }

        auto& set_file(bytefile* _bf){
            bf = _bf;
            ip = bf->code_ptr;

            log = stderr;

            return *this;
        }

        int run(){
            fprintf(log, "Entered main\n");
            
            do{
                char x = BYTE,
                     h = (x & 0xF0) >> 4,
                     l = x & 0x0F;
                // fprintf(log, "Processing instruction %s: ", instr_repr[h]);
                switch(h){
                    case 0: handle_binop(l);    break;
                    case 1: handle_stor(l);     break;
                    case 2:
                    case 3: 
                    case 4: handle_load(h, l);  break;
                    case 5: handle_control(l);  break;
                    case 6: handle_pattern(l);  break;
                    case 7: handle_builtins(l); break;
                    case 15: return 0;
                    default: throw interpreter_fail(h, l);
                }

            }while(true);
        }
    protected:
        void handle_binop(char l){
            // fprintf(log, "\n");
            int y = UNBOX(stack.pop());
            int x = UNBOX(stack.pop());
            int res = bops[l-1](x, y);
            stack.push(BOX(res));
        }

        void handle_stor(char l){
            // fprintf(log, "%s\n", stor_repr[l]);
            int res;
            switch (l) {
                    case 0: stack.push(BOX(INT));                                                    break;
                    case 1:{
                        int res = (int)make_string(STRING);
                        stack.push(res);
                    }                                                                                break;
                    case 2:{
                        int hash = LtagHash(STRING);
                        stack.push(make_sexp(INT, hash));
                    }                                                                                break;
                    case 3: throw interpreter_fail("STI is not supported");
                    case 4: {
                        int v = stack.pop(); 
                        int i = stack.pop(); 
                        int loc = stack.pop(); 
                        stack.push(Bsta((void*)v, i, (void*)loc));
                    }                                                                                break;
                    case 5: ip = bf->code_ptr + INT;                                                 break;
                    case 6:{
                        if (cur_scope->outer == nullptr) {
                            exit(0);//leaving main
                        }
                        res = stack.pop();
                        stack.sp = cur_scope->args;
                        ip = cur_scope->origin_ip;
                        cur_scope = cur_scope->outer;
                        stack.push(res);
                        // std::cerr << cur_scope->repr_scope() << std::endl;
                    }                                                                                break;
                    case  7: throw interpreter_fail("RET is not supported");
                    case  8: stack.pop();                                                            break;
                    case  9:{int v = stack.pop(); stack.push(v); stack.push(v);}                     break;
                    case 10:{int a = stack.pop();int b = stack.pop(); stack.push(b); stack.push(a);} break;
                    case 11:{
                        int b = stack.pop();
                        int a = stack.pop();
                        stack.push(Belem((void*)a, b));
                    }                                                                                break;
                    default: throw interpreter_fail("Invalid control instructin %d", l); 
            }
        }

        void handle_load(char h, char l){
            // fprintf(log, "%s\n", lds[h-2]);
            int *p = 0;
            switch (l) {
                case 0: p = bf->global_ptr  + INT;            break;
                case 1: p = cur_scope->vars + INT;            break;
                case 2: p = cur_scope->args + INT;            break;
                case 3: p = (int*)(*(cur_scope->acc + INT));  break;
                default: throw interpreter_fail(h, l);
            }
            switch(h){
                case 2: {int value = *p; stack.push(value);}                break; //LD
                case 3:  stack.push(p); stack.push(p);                      break; //LDA
                case 4: {int res = stack.pop(); *p = res; stack.push(res);} break; //ST
                default: throw interpreter_fail(h, l);
            }
        }

        void handle_control(char l){
            // fprintf(log, "%s\n", control_repr[l]);
            switch (l) {
                case 0: {int v = UNBOX(stack.pop()); int dst = INT; if (!v)ip = bf->code_ptr + dst;} break;
                case 1: {int v = UNBOX(stack.pop()); int dst = INT; if ( v)ip = bf->code_ptr + dst;} break;
                case 2: {
                    Scope* scope = (Scope*)malloc(sizeof(Scope));
                    scope->args = stack.sp;
                    stack.sp += INT + 1; 
                    scope->origin_ip = (char*)stack.pop();
                    scope->vars = stack.sp;
                    scope->acc = scope->vars;
                    stack.sp += INT; 
                    scope->outer = cur_scope;
                    cur_scope = scope;
                    // std::cerr << cur_scope->repr_scope() << std::endl;
                } break;
                case 3:{
                    Scope* scope = (Scope*)malloc(sizeof(Scope));
                    int n = INT;
                    scope->args = stack.sp;
                    stack.sp += n + 2;
                    n = stack.pop();
                    scope->origin_ip = (char *)stack.pop();
                    stack.sp += 2;
                    scope->acc = stack.sp;
                    stack.sp += n;
                    scope->vars = stack.sp;
                    stack.sp += INT;
                    scope->outer = cur_scope;
                    cur_scope = scope;
                    // std::cerr << cur_scope->repr_scope() << std::endl;
                } break;
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
                            default: throw interpreter_fail("failed in closure construction...");
                        }
                        stack.push(res);
                    } 
                    stack.push(make_closure(n, (void*)pos)); 
                    
                } break;
                case  5:{//CALLC
                    int n = INT;
                    data* d = TO_DATA(*(stack.sp - n - 1));
                    memmove(stack.sp - n - 1, stack.sp - n, n * sizeof(int));
                    stack.sp--;
                    int offset = *(int*)d->contents;
                    int accN = LEN(d->tag) - 1;
                    stack.push(ip);
                    stack.push(accN);
                    for (int i = accN - 1; i >= 0; i--) {
                        stack.push(((int*)d->contents) + i + 1);
                    }
                    ip = bf->code_ptr + offset;
                    stack.sp -= accN+n+2;
                } break;
                case 6 :{ 
                    int v = INT; 
                    int n = INT; 
                    stack.push(ip);
                    stack.push(0); 
                    ip = bf->code_ptr + v;
                    stack.sp -= (n + 2);
                } break;
                case 7 :{ //TAG
                    char* s = STRING;
                    int v = LtagHash(s);
                    int n = BOX(INT); 
                    int tg = Btag((void*)stack.pop(), v, n);
                    // fprintf(log, "got %s, LtagHash: box(%d) = %d. Btag: box(%d) = %d\n",
                    //         s, UNBOX(v), v, UNBOX(tg), tg);
                    stack.push(tg);
                } break;
                case 8 :{ 
                    int n = BOX(INT);
                    int pat = Barray_patt((void*)stack.pop(), n);
                    stack.push(pat);
                } break;
                case 9 :{ 
                    int a = BOX(INT);
                    int b = BOX(INT);
                    Bmatch_failure((void*)stack.pop(), "", a, b);
                } break;
                case 10: INT;                                                                            break;
                default: throw interpreter_fail("Invalid control instruction: %d", l); 
            }
        }

        void handle_pattern(char l){
            // fprintf(log, "%s\n", patt_repr[l]);
            int res;
            switch (l) {
                case 0: {
                    int a = stack.pop();
                    int b = stack.pop(); 
                    res = Bstring_patt((void*)a, (void*)b);
                } break;
                case 1: res = Bstring_tag_patt((void *)stack.pop());                  break;
                case 2: res = Barray_tag_patt((void *)stack.pop());                   break;
                case 5: res = Bunboxed_patt((void *)stack.pop());                     break;
                case 6: res = Bclosure_tag_patt((void *)stack.pop());                 break;
                default: throw interpreter_fail("Invalid pattern %d", l);
            } 
            stack.push(res); 
        }

        void handle_builtins(char l){
            // fprintf(log, "%s\n", builtins[l]);
            int res;
            switch (l){
                case 0: {
                    res = Lread();     
                    // std::cerr << "Read " << UNBOX(res) << " from console" << std::endl;    
                }                                                 break;
                case 1: {
                    int to_write = stack.pop();
                    // std::cerr << "Wrote " << UNBOX(to_write) << " to console" << std::endl;
                    res = Lwrite(to_write);
                }                                                 break;
                case 2: res = Llength((void *)stack.pop());       break;
                case 3: res = (int)Lstring((void *)stack.pop());  break;
                case 4: res = (int)make_array(INT);               break;
                default: throw interpreter_fail("Invalid builtin: %d", l); 
            }
            stack.push(res);
            
        }

        void* make_array(int n) {
            int     i, ai; 
            data    *r; 
            r = (data*) malloc (sizeof(int) * (n+1));
            r->tag = ARRAY_TAG | (n << 3);

            for (i = n -1; i >=0; i--) {
                ((int*)r->contents)[i] = stack.pop();
            }
            return r->contents;
        } 

        void* make_string(void *p) {
            int   n = strlen ((const char*)p);
            data *r = (data*) malloc (n + 1 + sizeof (int));
            r->tag = STRING_TAG | (n << 3);

            strncpy (r->contents, (const char*)p, n + 1);
            return r->contents;
        }              
    
        void* make_closure (int n, void *entry) {
            int     i, ai;
            data    *r; 

            r = (data*) malloc (sizeof(int) * (n+2));

            r->tag = CLOSURE_TAG | ((n + 1) << 3);
            ((void**) r->contents)[0] = entry;

            for (i = 0; i<n; i++) {
                ((int*)r->contents)[i+1] = stack.pop();
            }
            return r->contents;
        }
    
        void* make_sexp (int n, int hash) {
            // std::cerr << "Making sexp with " << n << " and " << hash << std::endl;
            int     i, ai;  
            sexp   *r;  
            data   *d;  

            r = (sexp*) malloc (sizeof(int) * (n + 2));

            d = &(r->contents);    
            d->tag = SEXP_TAG | (n << 3);

            for (i=n - 1; i>= 0; i--) {
              ((int*)d->contents)[i] = stack.pop();
            }

            r->tag = UNBOX(hash);

            return d->contents;
        }
    
    } interpreter;
}

int main(int argc, char*argv[]){
    using interpreter::interpreter;
    return interpreter.init()
                      .set_file(read_file(argv[1]))
                      .run();
}