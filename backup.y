%{
#include "my.h"
int level ;
int active_func_num;
struct symboltable *call_name_ptr;
struct symboltable st[50];
struct for_struct fs[10];
char result_type[20];
int param_count = 0;
int limit=-1;
int total_struct=-1;
int struct_flag = 0;
int e_type = 0;		// simple = 1 ; array = 2 ; pointer = 3 ; struct - 4 ; struct array - 5 ; struct pointer - 6;
int for_array[10]; // storing array indexes locally 
// intermediate starts
char quadcode[100];
quadraple global_table[100000];
int nextquad = 0;
int varcount = 1;
// ends here

extern int yylex();
extern int yyparse();
extern int yyerror();

void yyerror (const char *str)
{
	fprintf(stderr, "error: %s\n", str);		// error function
}


// main function 
int main() 
{
	yyparse(); // calling parse funtion 
	print_table();
	icprint();
	
}

%}

%union {
	int num;
	char *st;
	char fixstr[100];
	expression * expr;
	vector<int> *vec;
	while_ex *wex;
	
}
%token <fixstr> INT  FLOAT CHAR VOID MAIN WHILE STRING IF ELSE STRUCT IDENTIFIER NUMBER


%type<vec> block  define n_var ifblock whileblock vars_id
%type<fixstr> result idd datatype  idd2 idd3
%type <num>	 param_list plist   br_dimlist ifexp m_var 
%type<expr> term factor pm_exp d_exp or_exp exp lhs 
%type<wex> whileexp

%%

start:				start startdash | startdash | func_decl | struct_decl |start func_decl | start struct_decl;

/* -------------------for struct declartion ----------------------*/

struct_decl:		STRUCT IDENTIFIER '{'{struct_flag=1;} struct_block {struct_flag=0;}'}' ';' {

																	if(search_struct($2))
																		printf("%s struct declared before\n",$2 );
																	else
																	{
																		total_struct++;
																		strcpy(fs[total_struct].name,$2);
																		
																	}
																};


struct_block:		declaration struct_block | ;



/*------------------------------------------------------------------------*/

/*---------------- for function declartion-------------------------------*/

func_decl:			func_head  '{' block '}' {
												
												level = 0;
												char buffer[100];
												sprintf(buffer,"func end");
												generate(buffer);
											} ;

func_head:			red_id '(' decl_plist ')' {level = 2;
												st[limit].num_params = param_count;};

red_id:				result IDENTIFIER{	

										if(search_func($2)) printf("error : same function %s declared \n",$2);
										else 
											{
												enter_func($2,$1);
												char buffer[100];
												sprintf(buffer,"func begin %s",$2);
												generate(buffer);
											}
										
										level = 1;
										param_count =0;
									};

result:				INT {strcpy($$,$1);}
					| FLOAT {strcpy($$,$1);}
					| VOID{strcpy($$,$1);};

decl_plist:			decl_pl | ;

decl_pl:			decl_pl ',' decl_param
					| decl_param;


decl_param:			datatype IDENTIFIER{
										e_type = 1;
										if(search_param($2))
											printf("error: parameter, %s already declared\n",$2);
										else
											enter_param($2,$1);
									
										};	




/*------------------------------------------------------------------------*/

/* main function */

startdash:			void_main '(' ')' '{' block	'}' { 	char buffer[100];
														sprintf(buffer,"func end");
														generate(buffer);
														printf("\nSyntax is correct\n");
													};

void_main:			VOID MAIN{
								if(search_func($2)) 
									printf("error : same %s function declared before \n",$2);
								else
								{
									enter_func($2,$1);
									char buffer[100];
									sprintf(buffer,"func begin main");
									generate(buffer);
									
								}
									// active_func_ptr = st[limit]; 
									level = 2;
							};
/* body insite the function */

block:				whileblock{backpatch((*$1),nextquad);} block {$$ = new vector<int>;}
					| declaration block {$$ = new vector<int>;}
					| ifblock {backpatch((*$1),nextquad);}block{$$ = new vector<int>;}

					| func_call block{$$ = new vector<int>;}
					| define block{$$ = new vector<int>;}
					| '{' {level++; } block '}' {level--;} block {$$ = new vector<int>;}
					| /* e */{$$ = new vector<int>;}
					;
/* --------------for function call --------------------------*/
func_call:			func_func_call ';' ;

func_func_call:		IDENTIFIER '(' param_list ')' {	
													if(!search_func($1))
													{
														printf("%s function not declared\n",$1);
													}
													else
													{
														// printf("%d\n",$3 );
														if(st[active_func_num].num_params != $3)
															printf("mismatch in number of parameters in call and declaration in %s function\n",$1);
														else{
															char *var = nextvar();
															char buffer[100];
															// sprintf(buffer,"refparam  %s",var);
															sprintf(buffer,"call %s %d",$1,$3+1);
															generate(buffer);
														}
													}

												} ;

param_list:			plist{$$ = $1;} | {$$ = 0;};

plist:				e {$$ =  1;}| e ',' plist{$$ = $3 + 1;};

e: 					exp{	
							char buffer[100];
							sprintf(buffer,"param  %s",$1->value);
							generate(buffer);


						};
/*					| lhs '=' exp{
									if($1->type !=1 || $3->type != 1)
										printf("error : type mismatch of operands in assigment statement\n");
									else
									{

										char buffer[50];
										sprintf(buffer,"%s := %s ",$1->value , $3->value);
										
										generate(buffer);
									}
							};


e:					NUMBER 
					| v_id
					| v_id '=' func_func_call 
					| func_func_call 
					| v_id '=' v_id 
					| v_id '=' NUMBER
					;

v_id:				IDENTIFIER{	
								int f = search_vars($1);
								if(f==0)
								{
									f = search_param($1);
									if(!(level==2 && f!=0))
									{
										printf("%s is not declared before and using for func call \n",$1 );
									}
								}
							}; */
/*------------------------------------------------------------------------*/

/* ---------if -else------------------*/
// ifblock:			
ifblock:			ifexp '{' block '}' {
											$$ = new vector<int>;
											(*$$).push_back($1);
											merger((*$$),(*$3));	
											// backpatch((*$$),nextquad);
										}

					| ifexp  '{' block'}' n_var ELSE m_var  '{' block '}' {
																			$$  = new vector<int>;
																			global_table[$1].gotonum = $7;
																			merger((*$$),(*$3));
																			merger((*$$),(*$5));
																			merger((*$$),(*$9));
																			};



ifexp:				IF '(' exp ')'
								{
									
									$$ = nextquad;
									char buffer[100];
									sprintf(buffer,"if %s <=0 ",$3->value);
									generate(buffer);
								};

n_var: {
			$$ = new vector<int>;
			(*$$).push_back(nextquad);
			char buffer[100];
			sprintf(buffer," ");
			generate(buffer);
		};

m_var: {
			$$ = nextquad;

		};
/*------------while loop------------------------------*/
whileblock:			whileexp	'{' block '}' {	
												strcpy(global_table[nextquad].s, " ");
												global_table[nextquad].gotonum = $1->begin;
												nextquad = nextquad + 1;
												backpatch((*$3),$1->begin);
												$$ = new vector<int>;
												(*$$) = ($1->false_list);
												};


whileexp:		WHILE  m_var '(' exp ')' {	
											$$ = new while_ex;
											($$->false_list).push_back(nextquad);
											char buffer[50];
											sprintf(buffer,"if %s <= 0", $4->value);
											generate(buffer);
											$$->begin = $2;

											};

/*------------define variables -------------------------*/
define : 		vars_id{//$1 = new vector<int> ;
						//(*$$) = (*$1);
						};



vars_id:			lhs '=' exp ';' { 	
									if($1->type !=1 || $3->type != 1)
										printf("error : type mismatch of operands in assigment statement\n");
									else
									{

										char buffer[50];
										sprintf(buffer,"%s := %s ",$1->value , $3->value);
										
										generate(buffer);
									}
									$$ = new vector<int>;
								}

					| lhs '=' '&' IDENTIFIER ';'{	
												$$ = new vector<int>;
												int f = search_vars($4);
												if(f==0)
												{
													f = search_param($4);
													if(!(level==2 && f!=0))
													{
														printf("error: %s is not defined earlier\n",$4 );
														f = -1;
													}
												}
												else
												{
													if($1->type ==3 && f == 1)
													{
														char buffer[50];
														sprintf(buffer,"%s :=  &%s ",$1->value , $4);
														
														generate(buffer);
													}
													else{
														printf("error : type mismatch of operands in assigment statement\n");	
													}
												}

											};

lhs:				IDENTIFIER{	$$ = new expression;
								int f = search_vars($1);
								if(f==0)
								{
									f = search_param($1);
									if(!(level==2 && f!=0))
									{
										printf("error: %s is not defined earlier\n",$1 );
										$$->type = -1;
									}
								}
								else
								{
									$$->type = f;
									strcpy($$->value,$1);
								}

								}

					| IDENTIFIER  br_dimlist {	$$ = new expression;
												int f = array_valid($1,$2);
												// int i;
												// for(i=0;i<$2;i++)
												// printf("%d\n",for_array[i] );
												if(f==0)
												{
													f = search_param($1);
													if(!(level==2 && f!=0))
													{
														printf("error: %s is not defined earlier\n",$1 );
														$$->type = -1;
													}
												}
												else
												{
													$$->type = f;
													strcpy($$->value,$1);
												}
												};
/*------------------------------------------------------------------------*/

/*-----------variable declartion ------------------------------*/
declaration:		datatype{strcpy(result_type,$1);} vars ';';


datatype:			INT 
					| FLOAT 
					| CHAR
					| STRUCT IDENTIFIER{

										if(search_struct($2))
										{
											e_type = 4;
											strcat($1,"_");
											strcat($1,$2);
											strcpy($$,$1);
										}
										else
										{
											printf("error: struct name %s is undeclared  \n",$2 );
										}
								
								
					}
					;


vars:				array_id
					| array_id ',' vars;

array_id:			idd
					| idd '=' exp 
					| idd2 br_dimlist {
											// printf("%s\n",$1 );
											int i;
											// printf(" num_b = %d\n", $2 );
											// for(i=0;i<$2;i++)
											// 	printf("%d\n",for_array[i] );
											enter_num_b($1, $2);

										}
					| idd2 br_dimlist '=' '{' numlist '}' {
											enter_num_b($1, $2);
											
											
										}
					| '*' idd3 
					;



idd:				IDENTIFIER{	strcpy($$,$1);
								if(e_type==4)
									e_type = 4;
								else
									e_type = 1;

								if(struct_flag==0)
								{
									int f = search_vars($1); int f2 = search_param($1);
									if(f != 0)
									{
										printf("found same name var : %s\n",$1);
									}

									
									else if(level == 2 && f2 !=0 )
									{
										printf("found same parameter :%s  in  function\n",$1);
									}
									else
									{
										enter_vars($1);
									}
								}
								else
								{
									if(search_in_struct_var($1))
										printf("found same name var in struct  : %s\n",$1);
									else
										enter_in_struct($1);

								}

							};

idd2:				IDENTIFIER{	strcpy($$,$1);
								if(e_type==4)
									e_type = 5;
								else
									e_type = 2;
								
								if(struct_flag==0)
								{
									int f = search_vars($1); int f2 = search_param($1);
									if(f != 0)
										printf("found same name var : %s\n",$1);
									
									else if(level == 2 && f2 !=0 )
										printf("found same parameter :%s  in  function\n",$1);
									else
										enter_vars($1);
								}
								else
								{
									if(search_in_struct_var($1))
										printf("found same name var in struct  : %s\n",$1);
									else
										enter_in_struct($1);

								}

							};


idd3:				IDENTIFIER{	if(e_type==4)
									e_type = 6;
								else
									e_type = 3;
								strcpy($$,$1);
								if(struct_flag==0)
								{
									int f = search_vars($1); int f2 = search_param($1);
									if(f != 0)
										printf("found same name var : %s\n",$1);
									
									else if(level == 2 && f2 !=0 )
										printf("found same parameter :%s  in  function\n",$1);
									else
										enter_vars($1);
								}
								else
								{
									if(search_in_struct_var($1))
										printf("found same name var in struct  : %s\n",$1);
									else
										enter_in_struct($1);

								}

							};

numlist:			exp | exp ',' numlist;

br_dimlist:			'[' NUMBER ']' {$$ = 1;

									for_array[0] = sti($2);
									} 
					| '[' NUMBER ']' br_dimlist {$$ = $4 + 1;
										for_array[$$-1] = sti($2);
									} ;

/*------------------------------------------------------------------------*/


/*------------ Expression-------------------*/ 
exp:				or_exp '|' '|' exp { $$ = new expression;
											if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
												$$->type = 1;
											}
					| or_exp
					;

or_exp:				d_exp '&' '&' or_exp  {$$ = new expression;
											 if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
												$$->type = 1;
											}
					| d_exp
					;

d_exp:				pm_exp{
							
							$$ = new expression;
							(*$$) = (*$1);
							
							
						}	
					| pm_exp '>' pm_exp {$$ = new expression;
											 if($1->type !=1 || $3->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
											{
												$$->type = 1;
												char *var = nextvar();
												char buffer[50];
												sprintf(buffer,"%s := %s > %s",var , $1->value , $3->value);
												strcpy($$->value,var);
												generate(buffer);
											}
										}
					| pm_exp '!' '=' pm_exp{ $$ = new expression;
											if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
											{
												$$->type = 1;
												char *var = nextvar();
												char buffer[50];
												sprintf(buffer,"%s := %s != %s",var , $1->value , $4->value);
												strcpy($$->value,var);
												generate(buffer);
											}
											}
					| pm_exp '=' '=' pm_exp{ $$ = new expression;
											if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
											{
												$$->type = 1;
												char *var = nextvar();
												char buffer[50];
												sprintf(buffer,"%s := %s == %s",var , $1->value , $4->value);
												strcpy($$->value,var);
												generate(buffer);
											}
											}
					| pm_exp '<' pm_exp{ $$ = new expression;
										if($1->type !=1 || $3->type != 1)
										{
											printf("error : type mismatch in expersion\n");
											$$->type = -1;
										}
										else
										{
											$$->type = 1;
											char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s < %s",var , $1->value , $3->value);
											strcpy($$->value,var);
											generate(buffer);
										}
									}
					| pm_exp '<' '=' pm_exp{ $$ = new expression;
											if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
											{

												$$->type = 1;
												char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s <= %s",var , $1->value , $4->value);
											strcpy($$->value,var);
											generate(buffer);
											}
											}

					| pm_exp '>' '=' pm_exp{ $$ = new expression;
											if($1->type !=1 || $4->type != 1)
											{
												printf("error : type mismatch in expersion\n");
												$$->type = -1;
											}
											else
											{
												$$->type = 1;
												char *var = nextvar();
												char buffer[50];
												sprintf(buffer,"%s := %s >= %s",var , $1->value , $4->value);
												strcpy($$->value,var);
												generate(buffer);
											}
											}
					| '!' '(' exp ')'{$$ = new expression;
										$$->type = $3->type;
										char *var = nextvar();
										char buffer[50];
										sprintf(buffer,"%s := !%s",var, $3->value);
										strcpy($$->value,var);
										generate(buffer);
									}
					;

			

pm_exp:				factor	{
							
							$$ = new expression;
							(*$$) = (*$1);
							
							
						}	
					| pm_exp '+' factor{ $$ = new expression;
										if($1->type !=1 || $3->type != 1)
										{
											printf("error : type mismatch in expersion\n");
											$$->type = -1;
										}
										else
										{
											$$->type = 1;
											char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s + %s",var , $1->value , $3->value);
											strcpy($$->value,var);
											generate(buffer);
											
										}
										}
					| pm_exp '-' factor{ $$ = new expression;
											if($1->type !=1 || $3->type != 1)
										{
											printf("error : type mismatch in expersion\n");
											$$->type = -1;
										}
										else
										{
											$$->type = 1;
											char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s - %s",var , $1->value , $3->value);
											strcpy($$->value,var);
											generate(buffer);
											
											
										}
										}
					| '-' factor {

									$$ = new expression;
									$$->type = $2->type; 
									// $$->value = '-';
									char p[80] = "-";
									strcat(p,$2->value);
									strcpy($$->value,p);
								}
					;

factor:				term 
						{
							
							$$ = new expression;
							(*$$) = (*$1);
							
							
						}			
					|factor '*' term { 	
										$$ = new expression;
										
										if($1->type !=1 || $3->type != 1)
										{
											printf("error : type mismatch in expersion\n");
											$$->type = -1;
										}
										else
										{
											$$->type = 1;

											char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s * %s",var , $1->value , $3->value);
											strcpy($$->value,var);
											generate(buffer);
											
											
										}
									}
					| factor '/' term{ 
										$$ = new expression;
										if($1->type !=1 || $3->type != 1)
										{
											$$->type = -1;
											printf("error : type mismatch in expersion\n");
										}
										else
										{
											// printf("%s==%s\n", $1->value , $3->value);
											$$->type = 1;
											char *var = nextvar();
											char buffer[50];
											sprintf(buffer,"%s := %s / %s",var , $1->value , $3->value);
											
											generate(buffer);
											strcpy($$->value,var);

											
										}
											
									}
					;

term:				NUMBER{	
							$$ = new expression;
							strcpy($$->value,$1);
							(*$$).type = 1;
							// printf("ffff %s\n",$1 );
						}
					| IDENTIFIER{	
									$$ = new expression;
									// $$->value = (char * )malloc(1000*sizeof(char));
									int f = search_vars($1);
									strcpy($$->value,$1);
									// (*$$).value = $1;
									// printf("ffff %s\n",$$->value );

									if(f==0)
									{
										f = search_param($1);
										if(!(level==2 && f!=0))
										{
											printf("error: %s is not defined earlier\n",$1 );
											$$->type = -1;
										}
									}
									else
										$$->type = f;

								}

					/*| func_func_call*/
					| '(' exp ')' { $$ = new expression;$$->type = $2->type; strcpy($$->value,$2->value);}
					;


/*
done:
enter in main loop with void
while loop 
if -else done
condition
expersion
declare vars / array 
define vars 	all these cases done
				int a,c = 3	;
				a=1,c=2.2 + 5;
				int d[2] ;
				int k[2][3] = {4,4,2,1};
struct  done wth vars 
function
funtion calls
pointer is done
nested level is done 
Variable declaration checking
Type checking should include type coercibility and operator compatibility.
Scope checking

semantic :
	functions done

todo:
	handle data type char 
	assingment of array vars
	code generation

*/

%%

void enter_func(char name[] , char type[] )
{

	limit += 1;
	// printf("i m gonna insert in %d %s\n", limit,name);
	strcpy(st[limit].name,name);
	strcpy(st[limit].type,type);
	st[limit].param = NULL;
	st[limit].local = NULL;
}

void generate(char str[])
{
	quadraple q;
	// printf("%s\n",str );
	strcpy(q.s,str);	
	q.gotonum = -1;
	global_table[nextquad] = q;
	nextquad = nextquad + 1;
}

void enter_param(char id[],char type[])
{
	param_count++;
	struct varlist *new_node,*temp;

	new_node= (struct varlist *)malloc(sizeof(struct varlist));


 	strcpy(new_node->var_name,id);
 	strcpy(new_node->type,type);
 	new_node->level = 1;
 	new_node->next=NULL;
 	new_node->e_type = e_type;

	if(st[limit].param==NULL)
	{
	   st[limit].param=new_node;
	}
 	else
 	{
	   	temp = st[limit].param;
	    while(temp->next!=NULL)
	    {
	    	temp = temp->next;
	    }
	   temp->next = new_node;
 	}
}
void enter_vars(char id[])
{
	// printf("%s --- %d\n", id,level);
	struct varlist *new_node,*temp;

	new_node= (struct varlist *)malloc(sizeof(struct varlist));

	
 	strcpy(new_node->var_name,id);
 	strcpy(new_node->type,result_type);
 	new_node->level = level;
 	new_node->next=NULL;
 	new_node->e_type = e_type;
	if(st[limit].local==NULL)
	{
	   st[limit].local=new_node;
	}
 	else
 	{
	   	temp = st[limit].local;
	    while(temp->next!=NULL)
	    {
	    	temp = temp->next;
	    }
	   temp->next = new_node;
 	}
 	// printf("%s done\n",st[limit].local->var_name);
}


void print_table()
{
	int i;
	struct varlist *temp;
	printf("Symbol table\n");
	printf("--------------------------------\n");
	printf("name\ttype\tparam_count\n");
	printf("--------------------------------\n");
	for (i = 0;i<=limit;i++)
	{
		printf("%s\t",st[i].name );
		printf("%s\t",st[i].type );
		printf("%d\t",st[i].num_params);
		temp = st[i].param;
		printf("parmas:");
		while(temp!=NULL)
		{
			printf("%s-%s-%d-%d\t",temp->var_name,temp->type,temp->level,temp->e_type);
			temp = temp->next;
		}
		temp = st[i].local;
		printf("local:");
		while(temp!=NULL)
		{
			printf("%s-%s-%d-%d\t",temp->var_name,temp->type,temp->level , temp->e_type);
			temp = temp->next;
		}
		printf("\n");
	}
}
int search_param(char id[])
{
    struct varlist *current = st[limit].param;  // Initialize current
    while (current != NULL)
    {
        if(!strcmp(current->var_name,id))
            return (current->e_type);
        current = current->next;
    }
    return 0;
}

int search_vars(char id[])
{
    struct varlist *current = st[limit].local;  // Initialize current
    struct varlist *temp = st[limit].param;
    int f;
    while (current != NULL)
    {
        if(!strcmp(current->var_name,id) && current->level <= level)
        {
            return (current->e_type);
        }
        current = current->next;
    }


    return 0;
}

int array_valid(char id[] , int num_b)
{
	struct varlist *current = st[limit].local;  // Initialize current
    struct varlist *temp = st[limit].param;
    int f;
    while (current != NULL)
    {
        if(!strcmp(current->var_name,id) && current->level <= level)
        {
        	f = current->e_type;
        	if(f==2 && current->num_b == num_b)
        	{
        		int count = 0;
        		struct array_index *t;
        		t = current->array;
        		while(t != NULL)
        		{
        			if(!(for_array[count++] < t->a))
        				return -1;
        			t = t->next;
        		}
        		return 1;
        	}
            return (f);
        }
        current = current->next;
    }


    return 0;
}
int enter_num_b(char id[] , int num_b)
{
    struct varlist *current = st[limit].local;  // Initialize current
    struct varlist *temp = st[limit].param;
    int i;
    while (current != NULL)
    {
        if(!strcmp(current->var_name,id) && current->level <= level)
        {
        	current->num_b = num_b;
        	struct array_index *t , *t2 , *temp2;
        	t= (struct array_index*)malloc(sizeof(struct array_index));
        	t->a = for_array[0];
        	// printf("%d\n",for_array[0]);
        	t->next = NULL;
        	current->array = t;
        	t2 = t;
        	for(i=1;i<num_b;i++)
        	{
        		temp2 = (struct array_index*)malloc(sizeof(struct array_index));
        		temp2->a = for_array[i];
        		temp2->next = NULL;
        		t2->next = temp2;
        		t2 = temp2;
        		// printf("%d\n",for_array[i] );
        	}
   //      	struct array_index *pre;
   //      	pre = current->array;
			// while(pre != NULL)
			// {
			// 	printf("%d---",pre->a );
			// 	pre = pre->next;
			// }
            return (current->e_type);
        }
        current = current->next;
    }


    return 0;
}

int search_func(char name[])
{

	int i = 0;
	for(i=0;i<=limit;i++)
	{
		if(!strcmp(st[i].name,name))
		{
			active_func_num = i;		// for function call
			return 1;
		}
	}
	return 0;
}

int search_struct(char name[])
{

	int i = 0;
	for(i=0;i<=total_struct;i++)
	{
		if(!strcmp(fs[i].name,name))
		{		
			return 1;
		}
	}
	return 0;
}

void enter_in_struct(char id[])
{
	// printf("%s --- %d\n", id,level);
	struct varlist *new_node,*temp;
	new_node= (struct varlist *)malloc(sizeof(struct varlist));


	
 	strcpy(new_node->var_name,id);
 	strcpy(new_node->type,result_type);
 	new_node->level = 0;
 	new_node->next=NULL;

	if(fs[total_struct].local==NULL)
	{
	   fs[total_struct].local=new_node;
	}
 	else
 	{
	   	temp = fs[total_struct].local;
	    while(temp->next!=NULL)
	    {
	    	temp = temp->next;
	    }
	   temp->next = new_node;
 	}
 	// printf("%s done\n",st[limit].local->var_name);
}
int search_in_struct_var(char id[])
{
	struct varlist *current = fs[total_struct].local;  // Initialize current

    while (current != NULL)
    {
        if(!strcmp(current->var_name,id))
            return 1;
        current = current->next;
    }


    return 0;
}

void icprint()
{
	int i;
	printf("printing Three Address Code \n");
	for(i=0;i<nextquad;i++)
	{
		if(global_table[i].gotonum == -1)
		{
			printf("%d\t %s\n",i,global_table[i].s );
		}
		else
		{
			printf("%d\t %s goto  %d\n",i,global_table[i].s , global_table[i].gotonum);
		}
	}
}

char* nextvar(){
    char b[20];
    sprintf(b,"T_%d",varcount++);
    // addSymbolToQueue(buffer, ST_INT, 0);
    return strdup(b);
}

int sti(char *s)
{
	int r=0;
	for(int i=0;i<strlen(s);i++)
	{
		r= r*10  + (s[i]-48);
	}
	return r;
}

void merger(vector<int> &a,vector<int> &b)
{
	for(int i=0;i<b.size();i++)
	{
		a.push_back(b[i]);
	}
}

void backpatch(vector<int> &a,int b)
{
	for(int i=0;i<a.size();i++)
	{
		// printf("%d\n",a[i] );
		global_table[a[i]].gotonum = b;
	}
}