/* Lama SM Bytecode interpreter */

# include <string.h>
# include <stdio.h>
# include <errno.h>
# include <malloc.h>
# include "../runtime/runtime.h"

void *__start_custom_data;
void *__stop_custom_data;

typedef struct {
  char *string_ptr;
  int  *public_ptr;
  char *code_ptr;
  int   stringtab_size;
  int   global_area_size;
  int   public_symbols_number;
  char  buffer[0];
} bytefile;

char* get_string (bytefile *f, int pos) {
  return &f->string_ptr[pos];
}

char* get_public_name (bytefile *f, int i) {
  return get_string (f, f->public_ptr[i*2]);
}

int get_public_offset (bytefile *f, int i) {
  return f->public_ptr[i*2+1];
}

bytefile* read_file (char *fname) {
  FILE *f = fopen (fname, "rb");
  long size;
  bytefile *file;

  if (f == 0) {
    failure ("%s\n", strerror (errno));
  }
  
  if (fseek (f, 0, SEEK_END) == -1) {
    failure ("%s\n", strerror (errno));
  }

  file = (bytefile*) malloc (sizeof(int)*3 + (size = ftell (f)));

  if (file == 0) {
    failure ("*** FAILURE: unable to allocate memory.\n");
  }
  
  rewind (f);

  if (size != fread (&file->stringtab_size, 1, size, f)) {
    failure ("%s\n", strerror (errno));
  }
  
  fclose (f);
  
  file->string_ptr = &file->buffer [file->public_symbols_number * 2 * sizeof(int)];
  file->public_ptr = (int*) file->buffer;
  file->code_ptr   = &file->string_ptr [file->stringtab_size];
  
  return file;
}

void disassemble (FILE *f, bytefile *bf) {
  
# define INT    (ip += sizeof (int), *(int*)(ip - sizeof (int)))
# define BYTE   *ip++
# define STRING get_string (bf, INT)
# define FAIL   failure ("ERROR: invalid opcode %d-%d\n", h, l)
  
  char *ip     = bf->code_ptr;
  char *ops [] = {"+", "-", "*", "/", "%", "<", "<=", ">", ">=", "==", "!=", "&&", "!!"};
  char *pats[] = {"=str", "#string", "#array", "#sexp", "#ref", "#val", "#fun"};
  char *lds [] = {"LD\t", "LDA\t", "ST\t"};
  do {
    char x = BYTE,
         h = (x & 0xF0) >> 4,
         l = x & 0x0F;

    fprintf (f, "0x%.8x:\t", ip-bf->code_ptr-1);
    
    switch (h) {
    case 15:
      goto stop;
      
    /* BINOP */
    case 0:
      fprintf (f, "BINOP\t%s", ops[l-1]);
      break;
      
    case 1:
      switch (l) {
      case  0:
        fprintf (f, "CONST\t%d", INT);
        break;
        
      case  1:
        fprintf (f, "STRING\t%s", STRING);
        break;
          
      case  2:
        fprintf (f, "SEXP\t%s ", STRING);
        fprintf (f, "%d", INT);
        break;
        
      case  3:
        fprintf (f, "STI");
        break;
        
      case  4:
        fprintf (f, "STA");
        break;
        
      case  5:
        fprintf (f, "JMP\t0x%.8x", INT);
        break;
        
      case  6:
        fprintf (f, "END");
        break;
        
      case  7:
        fprintf (f, "RET");
        break;
        
      case  8:
        fprintf (f, "DROP");
        break;
        
      case  9:
        fprintf (f, "DUP");
        break;
        
      case 10:
        fprintf (f, "SWAP");
        break;

      default:
        FAIL;
      }
      break;
      
    case 2:
    case 3:
    case 4:
      fprintf (f, "%s\t", lds[h-2]);
      switch (l) {
      case 0: fprintf (f, "G(%d)", INT); break;
      case 1: fprintf (f, "L(%d)", INT); break;
      case 2: fprintf (f, "A(%d)", INT); break;
      case 3: fprintf (f, "C(%d)", INT); break;
      default: FAIL;
      }
      break;
      
    case 5:
      switch (l) {
      case  0:
        fprintf (f, "CJMPz\t%0x.8x", INT);
        break;
        
      case  1:
        fprintf (f, "CJMPnz\t%0x.8x", INT);
        break;
        
      case  2:
        fprintf (f, "BEGIN\t%d ", INT);
        fprintf (f, "%d", INT);
        break;
        
      case  3:
        fprintf (f, "CBEGIN\t%d ", INT);
        fprintf (f, "%d", INT);
        break;
        
      case  4:
        fprintf (f, "CLOSURE\t0x%.8x", INT);
        {int n = INT;
         for (int i = 0; i<n; i++) {
         switch (BYTE) {
           case 0: fprintf (f, "G(%d)", INT); break;
           case 1: fprintf (f, "L(%d)", INT); break;
           case 2: fprintf (f, "A(%d)", INT); break;
           case 3: fprintf (f, "C(%d)", INT); break;
           default: FAIL;
         }
         }
        };
        break;
          
      case  5:
        fprintf (f, "CALLC\t%d", INT);
        break;
        
      case  6:
        fprintf (f, "CALL\t%0x%.8x ", INT);
        fprintf (f, "%d", INT);
        break;
        
      case  7:
        fprintf (f, "TAG\t%s ", STRING);
        fprintf (f, "%d", INT);
        break;
        
      case  8:
        fprintf (f, "ARRAY\t%d", INT);
        break;
        
      case  9:
        fprintf (f, "FAIL\t%d", INT);
        fprintf (f, "%d", INT);
        break;
        
      case 10:
        fprintf (f, "LINE\t%d", INT);
        break;

      default:
        FAIL;
      }
      break;
      
    case 6:
      fprintf (f, "PATT\t%s", pats[l]);
      break;

    default:
      FAIL;
    }

    fprintf (f, "\n");
  }
  while (1);
 stop: {}
}

void dump_file (FILE *f, bytefile *bf) {
  int i;
  
  fprintf (f, "String table size       : %d\n", bf->stringtab_size);
  fprintf (f, "Global area size        : %d\n", bf->global_area_size);
  fprintf (f, "Number of public symbols: %d\n", bf->public_symbols_number);
  fprintf (f, "Public symbols          :\n");

  for (i=0; i < bf->public_symbols_number; i++) 
    fprintf (f, "   0x%.8x: %s\n", get_public_offset (bf, i), get_public_name (bf, i));

  fprintf (f, "Code:\n");
  disassemble (f, bf);
}

int main (int argc, char* argv[]) {
  bytefile *f = read_file (argv[1]);
  dump_file (stdout, f);
  return 0;
}
