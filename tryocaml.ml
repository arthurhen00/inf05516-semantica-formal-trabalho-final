(* auxiliares *)

let rec lookup amb x  =
  match amb with
    [] -> None
  | (y, item) :: tl -> if (y=x) then Some item else lookup tl x
                   
let rec update amb x item  =
  (x,item) :: amb


(* remove elementos repetidos de uma lista *)
let nub l =
  let ucons h t = if List.mem h t then t else h::t in
  List.fold_right ucons l []


(* calcula  l1 - l2 (como sets) *)
let diff (l1:'a list) (l2:'a list) : 'a list =
  List.filter (fun a -> not (List.mem a l2)) l1


(* tipos de L1 *)

type tipo = 
    TyInt
  | TyBool
  | TyFn     of tipo * tipo
  | TyPair   of tipo * tipo 
  | TyVar    of int   (* variáveis de tipo -- números *)
  | TyList   of tipo
  | TyMaybe  of tipo
  | TyEither of tipo * tipo
                      
type politipo = (int list) * tipo
  

(* free type variables em um tipo *)
           
let rec ftv (tp:tipo) : int list =
  match tp with
    TyInt  
  | TyBool -> []
  | TyFn(t1,t2)    
  | TyPair(t1,t2) ->  (ftv t1) @ (ftv t2)
  | TyVar n      -> [n]
  | TyList t -> ftv t
  | TyMaybe t -> ftv t
  | TyEither(t1,t2) -> (ftv t1) @ (ftv t2)


                   
(* impressao legível de monotipos  *)

let rec tipo_str (tp:tipo) : string =
  match tp with
    TyInt           -> "int"
  | TyBool          -> "bool"      
  | TyFn   (t1,t2)  -> "("  ^ (tipo_str t1) ^ "->" ^ (tipo_str t2) ^ ")"
  | TyPair (t1,t2)  -> "("  ^ (tipo_str t1) ^  "*" ^ (tipo_str t2) ^ ")" 
  | TyVar  n        -> "X" ^ (string_of_int n)
  | TyList t        -> (tipo_str t) ^ " list" 
  | TyMaybe t       -> "maybe " ^ (tipo_str t)
  | TyEither (t1,t2) -> "(either " ^ (tipo_str t1) ^ " " ^ (tipo_str t2) ^ ")"
                             
  

(********************************************)                     
(* expressões de L1 sem anotações de tipo   *)
           
type ident = string
 
type bop = Sum | Sub | Mult | Eq | Gt | Lt | Geq | Leq 
                                               
type expr  =
    Num       of int 
  | Bool      of bool
  | Var       of ident
  | Binop     of bop * expr * expr
  | Pair      of expr * expr
  | Fst       of expr
  | Snd       of expr
  | If        of expr * expr * expr
  | Fn        of ident * expr                   
  | App       of expr * expr
  | Let       of ident * expr * expr           
  | LetRec    of ident * ident * expr * expr 
  | Pipe      of expr * expr
  | Nil
  | Cons      of expr * expr
  | PMList    of ident * ident * expr * expr * expr
  | Nothing 
  | Just      of expr
  | PMJust    of ident * expr * expr * expr
  | Left      of expr
  | Right     of expr
  | PMLR      of ident * ident * expr * expr * expr
                   (*
                     | Hd        of expr
                     | Tl        of expr
                     | IsEmpty   of expr
                     | IsNothing of expr 
                     | FromJust  of expr * expr
  *)
(* impressão legível de expressão *)
     
let rec expr_str (e:expr) : string  =
  match e with 
    Num n   -> string_of_int  n
  | Bool b  -> string_of_bool b
  | Var x -> x     
  | Binop (o,e1,e2) ->  
      let s = (match o with
            Sum  -> "+"
          | Sub  -> "-"
          | Mult -> "*"
          | Leq  -> "<="
          | Geq  -> ">="
          | Eq   -> "="
          | Lt   -> "<"
          | Gt   -> ">") in
      "( " ^ (expr_str e1) ^ " " ^ s ^ " " ^ (expr_str e2) ^ " )"
  | Pair (e1,e2) ->  "(" ^ (expr_str e1) ^ "," ^ (expr_str e2) ^ ")"  
  | Fst e1 -> "fst " ^ (expr_str e1)
  | Snd e1 -> "snd " ^ (expr_str e1)
  | If (e1,e2,e3) -> "(if " ^ (expr_str e1) ^ " then "
                     ^ (expr_str e2) ^ " else "
                     ^ (expr_str e3) ^ " )"
  | Fn (x,e1) -> "(fn " ^ x ^ " => " ^ (expr_str e1) ^ " )"
  | App (e1,e2) -> "(" ^ (expr_str e1) ^ " " ^ (expr_str e2) ^ ")"
  | Let (x,e1,e2) -> "(let " ^ x ^ "=" ^ (expr_str e1) ^ "\nin "
                     ^ (expr_str e2) ^ " )"
  | LetRec (f,x,e1,e2) -> "(let rec " ^ f ^ "= fn " ^ x ^ " => "
                          ^ (expr_str e1) ^ "\nin " ^ (expr_str e2) ^ " )"
  | Pipe (e1,e2) -> "(" ^ (expr_str e1) ^ " |> " ^ (expr_str e2) ^ ")"
  | Nil -> "Nil"
  | Cons (e1,e2) -> (expr_str e1) ^ "::" ^ (expr_str e2)
  | PMList(x, xs, e1,e2, e3) -> "ListPatternMatching(" ^ (expr_str e1) ^ ", " ^ (expr_str e2) ^ ", " ^ (expr_str e3) ^")" 
  | Nothing -> "Nothing" 
  | Just e1 -> "Just(" ^ (expr_str e1) ^ ")"
  | PMJust(x,e1,e2,e3) -> "JustPatternMatching(" ^ (expr_str e1) ^ ", " ^ (expr_str e2) ^ ", " ^ (expr_str e3) ^")" 
  | Left e1 -> "Left(" ^ (expr_str e1) ^ ")"
  | Right e1 -> "Right(" ^ (expr_str e1) ^ ")"
  | PMLR(x, y, e1,e2, e3) -> "LeftRightPatternMatching(" ^ (expr_str e1) ^ ", " ^ (expr_str e2) ^ ", " ^ (expr_str e3) ^")" 
                               (*
                                 | Hd e1 -> "Hd(" ^ (expr_str e1) ^ ")"
                                 | Tl e1 -> "Tl(" ^ (expr_str e1) ^ ")"
                                 | IsEmpty e1 -> "IsEmpty(" ^ (expr_str e1) ^ ")"
                                 | IsNothing e1 -> "IsNothing(" ^ (expr_str e1) ^ ")"
                                 | FromJust(e1,e2) -> "FromJust(" ^ (expr_str e1) ^ " " ^ (expr_str e1) ^ ")"
                    *)
                                           
                          

         
(* ambientes de tipo - modificados para polimorfismo *) 
 
type tyenv = (ident * politipo) list 

 
(* calcula todas as variáveis de tipo livres
   do ambiente de tipos *)          
let rec ftv_amb' (g:tyenv) : int list =
  match g with
    []           -> []
  | (x,(vars,tp))::t  -> (diff (ftv tp) vars)  @  (ftv_amb' t)
                                               
                                               
let ftv_amb (g:tyenv) : int list = nub (ftv_amb' g)


               
(* equações de tipo  *)
 
type equacoes_tipo = (tipo * tipo) list

(*
   a lista
       [ (t1,t2) ; (u1,u2) ]
   representa o conjunto de equações de tipo
       { t1=t2, u1=u2 }
 *)
                 

(* imprime equações *)

let rec print_equacoes (c:equacoes_tipo) =
  match c with
    []       -> 
      print_string "\n";
  | (a,b)::t -> 
      print_string (tipo_str a);
      print_string " = ";
      print_string (tipo_str b);
      print_string "\n";
      print_equacoes t

                 

(* código para geração de novas variáveis de tipo *)
                 
let lastvar = ref 0

let newvar (u:unit) : int =
  let x = !lastvar
  in lastvar := (x+1) ; x 

(* substituições de tipo *)
                     
type subst = (int * tipo) list

    
(* imprime substituições  *)
               
let rec print_subst (s:subst) =
  match s with
    []       -> 
      print_string "\n";
  | (a,b)::t -> 
      print_string ("X" ^ (string_of_int a));
      print_string " |-> ";
      print_string (tipo_str b);
      print_string "\n";
      print_subst t

           
(* aplicação de substituição a tipo *)
           
let rec appsubs (s:subst) (tp:tipo) : tipo =
  match tp with
    TyInt             -> TyInt
  | TyBool            -> TyBool      
  | TyFn     (t1,t2)  -> TyFn     (appsubs s t1, appsubs s t2)
  | TyPair   (t1,t2)  -> TyPair   (appsubs s t1, appsubs s t2) 
  | TyVar  x        -> (match lookup s x with
        None        -> TyVar x
      | Some tp'    -> tp') 
  | TyList t          -> TyList(appsubs s t)
  | TyMaybe t         -> TyMaybe(appsubs s t)
  | TyEither (t1,t2) -> TyEither(appsubs s t1, appsubs s t2)
                         
  

(* aplicação de substituição a coleção de constraints *)
let rec appconstr (s:subst) (c:equacoes_tipo) : equacoes_tipo =
  List.map (fun (a,b) -> (appsubs s a,appsubs s b)) c


                     
(* composição de substituições: s1 o s2  *)
let rec compose (s1:subst) (s2:subst) : subst =
  let r1 = List.map (fun (x,y) -> (x, appsubs s1 y))      s2 in
  let (vs,_) = List.split s2                                 in
  let r2 = List.filter (fun (x,y) -> not (List.mem x vs)) s1 in
  r1@r2

 
(* testa se variável de tipo ocorre em tipo *)
                 
let rec var_in_tipo (v:int) (tp:tipo) : bool =
  match tp with
    TyInt             -> false
  | TyBool            -> false      
  | TyFn     (t1,t2)  -> (var_in_tipo v t1) || (var_in_tipo v t2)
  | TyPair   (t1,t2)  -> (var_in_tipo v t1) || (var_in_tipo v t2) 
  | TyVar  x          -> v=x
  | TyList t          -> (var_in_tipo v t)
  | TyMaybe t         -> (var_in_tipo v t)
  | TyEither(t1,t2)   -> (var_in_tipo v t1) || (var_in_tipo v t2) 
                         

(* cria novas variáveis para politipos quando estes são instanciados *)
                       
let rec renamevars (pltp : politipo) : tipo =
  match pltp with
    ( []       ,tp)  -> tp
  | ((h::vars'),tp)  -> let h' = newvar() in
      appsubs [(h,TyVar h')] (renamevars (vars',tp))

 
(* unificação *)
             
exception UnifyFail of (tipo*tipo)
                       
let rec unify (c:equacoes_tipo) : subst =
  match c with
    []                                    -> []
  | (TyInt,TyInt)  ::c'                   -> unify c'
  | (TyBool,TyBool)::c'                   -> unify c'
  | (TyFn(x1,y1),TyFn(x2,y2))::c'         -> unify ((x1,x2)::(y1,y2)::c')
  | (TyList(x1), TyList(x2))::c'          -> unify ((x1,x2)::c')
  | (TyMaybe(x1), TyMaybe(x2))::c'        -> unify ((x1,x2)::c')
  | (TyPair(x1,y1),TyPair(x2,y2))::c'     -> unify ((x1,x2)::(y1,y2)::c') 
  | (TyEither(x1,y1),TyEither(x2,y2))::c' -> unify ((x1,x2)::(y1,y2)::c') 
  | (TyVar x1, TyVar x2)::c' when x1=x2   -> unify c'

  | (TyVar x1, tp2)::c'                  -> if var_in_tipo x1 tp2
      then raise (UnifyFail(TyVar x1, tp2))
      else compose
          (unify (appconstr [(x1,tp2)] c'))
          [(x1,tp2)]  

  | (tp1,TyVar x2)::c'                  -> if var_in_tipo x2 tp1
      then raise (UnifyFail(tp1,TyVar x2))
      else compose
          (unify (appconstr [(x2,tp1)] c'))
          [(x2,tp1)]

  | (tp1,tp2)::c' -> raise (UnifyFail(tp1,tp2))
  
  
                       

exception CollectFail of string

               
let rec collect (g:tyenv) (e:expr) : (equacoes_tipo * tipo)  =

  match e with 
    Var x   ->
      (match lookup g x with
         None        -> raise (CollectFail x)
       | Some pltp -> ([],renamevars pltp))  (* instancia poli *)

  | Num n -> ([],TyInt)

  | Bool b  -> ([],TyBool)

  | Binop (o,e1,e2) ->  
      if List.mem o [Sum;Sub;Mult]
      then
        let (c1,tp1) = collect g e1 in
        let (c2,tp2) = collect g e2 in
        (c1@c2@[(tp1,TyInt);(tp2,TyInt)] , TyInt)
      else  
        let (c1,tp1) = collect g e1 in
        let (c2,tp2) = collect g e2 in
        (c1@c2@[(tp1,TyInt);(tp2,TyInt)] , TyBool)    

  | Pair (e1,e2) ->
      let (c1,tp1) = collect g e1 in
      let (c2,tp2) = collect g e2 in
      (c1@c2, TyPair(tp1,tp2))    
       
  | Fst e1 ->
      let tA = newvar() in
      let tB = newvar() in
      let (c1,tp1) = collect g e1 in
      (c1@[(tp1,TyPair(TyVar tA, TyVar tB))], TyVar tA)

  | Snd e1 ->
      let tA = newvar() in
      let tB = newvar() in
      let (c1,tp1) = collect g e1 in        
      (c1@[(tp1,TyPair(TyVar tA,TyVar tB))], TyVar tB)        

  | If (e1,e2,e3) ->
      let (c1,tp1) = collect g e1 in
      let (c2,tp2) = collect g e2 in
      let (c3,tp3) = collect g e3 in        
      (c1@c2@c3@[(tp1,TyBool);(tp2,tp3)], tp2)

  | Fn (x,e1) ->
      let tA       = newvar()           in
      let g'       = (x,([],TyVar tA)):: g in
      let (c1,tp1) = collect g' e1      in
      (c1, TyFn(TyVar tA,tp1))
         
  | App (e1,e2) ->
      let (c1,tp1) = collect  g e1 in
      let (c2,tp2) = collect  g e2  in
      let tA       = newvar()       in 
      (c1@c2@[(tp1,TyFn(tp2,TyVar tA))]
      , TyVar tA) 
      
  | Let (x,e1,e2) ->
      let (c1,tp1) = collect  g e1                    in
     
      let s1       = unify c1                         in
      let tf1      = appsubs s1 tp1                   in
      let polivars = nub (diff (ftv tf1) (ftv_amb g)) in
      let g'       = (x,(polivars,tf1))::g            in

      let (c2,tp2) = collect  g' e2                   in                    
      (c1@c2, tp2) 

  | LetRec (f,x,e1,e2) ->
      let tA = newvar() in
      let tB = newvar() in  
      let g2 = (f,([],TyFn(TyVar tA,TyVar tB)))::g            in
      let g1 = (x,([],TyVar tA))::g2                          in
      let (c1,tp1) = collect g1 e1                          in

      let s1       = unify (c1@[(tp1,TyVar tB)])            in
      let tf1      = appsubs s1 (TyFn(TyVar tA,TyVar tB))   in
      let polivars = nub (diff (ftv tf1) (ftv_amb g))       in
      let g'       = (f,(polivars,tf1))::g                    in    

      let (c2,tp2) = collect g' e2                          in
      (c1@[(tp1,TyVar tB)]@c2, tp2)
     
  | Pipe (e1, e2) ->
      let (c1, tp1) = collect g e1 in
      let (c2, tp2) = collect g e2 in
      let tA = newvar () in
      let tFn = TyFn (tp1, TyVar tA) in
      (c1 @ c2 @ [(tp2, tFn)], TyVar tA)      
 
  | Nil -> 
      let tA = newvar() in 
      ([], TyList (TyVar tA))
      
  | Cons (e1, e2) -> 
      let (c1, tp1) = collect g e1 in
      let (c2, tp2) = collect g e2 in 
      (c1@c2@[(TyList(tp1), tp2)], tp2)
      
  | PMList(x, xs, e1, e2, e3) ->
      let(c1, tp1) = collect g e1 in
      let(c2, tp2) = collect g e2 in
      let tA = newvar() in
      let g1 = (x,([],TyVar tA))::g in
      let g2 = (xs,([],TyList(TyVar tA) ))::g1 in
      let(c3, tp3) = collect g2 e3 in
      (c1@c2@c3@[(tp1, TyList(TyVar tA));(tp2, tp3)], tp2)
      
  | Nothing -> 
      let tA = newvar() in 
      ([], TyMaybe (TyVar tA))
      
  | Just(e1) ->
      let (c1, tp1) = collect g e1 in 
      (c1, TyMaybe(tp1))
      
  | PMJust (x,e1,e2,e3) ->
      let tA = newvar() in 
      let(c1, tp1) = collect g e1 in
      let(c2, tp2) = collect g e2 in
      let g1 = (x,([],TyVar tA))::g in 
      let(c3, tp3) = collect g1 e3 in
      (c1@c2@c3@[(tp1, TyMaybe(TyVar tA));(tp2, tp3)], tp2) 
      
  | Left (e1) ->
      let (c1, tp1) = collect g e1 in
      let tA = newvar () in
      (c1, TyEither(tp1, TyVar tA))
      
  | Right (e1) ->
      let (c1, tp1) = collect g e1 in
      let tA = newvar () in
      (c1, TyEither(TyVar tA, tp1))
  
  | PMLR (x, y, e1, e2, e3) ->
      let(c1, tp1) = collect g e1 in
      let tA = newvar() in
      let tB = newvar() in
      let g1 = (x,([],TyVar tA))::g in
      let g2 = (y,([],TyVar tB))::g in
      let(c2, tp2) = collect g1 e2 in
      let(c3, tp3) = collect g2 e3 in
      (c1@c2@c3@[(tp1, TyEither(TyVar tA, TyVar tB));(tp2, tp3)], tp2)
      
        (*
          | Hd (e1) ->
            let (c1, tp1) = collect g e1 in
            let tA = newvar() in 
            (c1@[(tp1, TyList(TyVar tA))], TyVar tA)
      
          | Tl (e1) -> 
            let (c1, tp1) = collect g e1 in
            let tA = newvar() in 
            (c1@[(tp1, TyList(TyVar tA))], TyList(TyVar tA))
      
          | IsEmpty (e1) ->
            let (c1, tp1) = collect g e1 in
            let tA = newvar() in 
            (c1@[(tp1, TyList(TyVar tA))], TyBool)
  
          | IsNothing (e1) ->
            let (c1, tp1) = collect g e1 in
            let tA = newvar() in 
            (c1@[(tp1, TyMaybe(TyVar tA))], TyBool)
      
          | FromJust (e1, e2) ->
            let (c1, tp1) = collect g e1 in
            let (c2, tp2) = collect g e2 in
            (c1@c2@[(TyMaybe(tp1), tp2)], tp1)
      *)
  
      
  
  

(* INFERÊNCIA DE TIPOS - CHAMADA PRINCIPAL *)
       
let type_infer (e:expr) : unit =
  print_string "\nExpressão:\n";
  print_string (expr_str e);
  print_string "\n\n";
  try
    let (c,tp) = collect [] e  in
    let s      = unify c       in
    let tf     = appsubs s tp  in
    print_string "\nEquações de tipo coletadas:\n";
    print_equacoes c;
    print_string "Tipo inferido: ";    
    print_string (tipo_str tp);
    print_string "\n\nSubstituição produzida por unify:\n";
    print_subst s;
    print_string "Tipo inferido (após subs): ";
    print_string (tipo_str tf);
    print_string "\n\n"

  with
   
  | CollectFail x   ->
      print_string "Erro: variável ";
      print_string x;
      print_string "não declarada!\n\n"
                     
  | UnifyFail (tp1,tp2) ->
      print_string "Erro: impossível unificar os tipos\n* ";
      print_string (tipo_str tp1);
      print_string "\n* ";
      print_string (tipo_str tp2);
      print_string "\n\n"
     
     
        (*===============================================*)

type valor =
    VNum   of int
  | VBool  of bool
  | VPair  of valor * valor 
  | VClos  of ident * expr * renv
  | VRclos of ident * ident * expr * renv
  | Vnil
  | Vcons of valor * valor
  | Vnothing 
  | Vjust    of valor
  | VLeft of valor
  | VRight of valor
and
  renv = (ident * valor) list
   
exception BugTypeInfer
exception DivZero
exception Test of string

let compute (oper: bop) (v1: valor) (v2: valor) : valor =
  match (oper, v1, v2) with
    (Sum, VNum(n1), VNum(n2)) -> VNum (n1 + n2)
  | (Sub, VNum(n1), VNum(n2)) -> VNum (n1 - n2)
  | (Mult, VNum(n1),VNum(n2)) -> VNum (n1 * n2) 
  | (Eq, VNum(n1), VNum(n2))  -> VBool (n1 = n2)  
  | (Gt, VNum(n1), VNum(n2))  -> VBool (n1 > n2)
  | (Lt, VNum(n1), VNum(n2))  -> VBool (n1 < n2)
  | (Geq, VNum(n1), VNum(n2)) -> VBool (n1 >= n2)
  | (Leq, VNum(n1), VNum(n2)) -> VBool (n1 <= n2)
  | _ -> raise BugTypeInfer


let rec eval (renv:renv) (e:expr) : valor =
  match e with
    Num n -> VNum n
               
  | Bool b -> VBool b

  | Var x ->
      (match lookup renv x with
         None -> raise BugTypeInfer
       | Some v -> v)
     
  | Binop(oper,e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      compute oper v1 v2

  | Pair(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2
      in VPair(v1,v2)

  | Fst e ->
      (match eval renv e with
       | VPair(v1,_) -> v1
       | _ -> raise BugTypeInfer)

  | Snd e ->
      (match eval renv e with
       | VPair(_,v2) -> v2
       | _ -> raise BugTypeInfer)


  | If(e1,e2,e3) ->
      (match eval renv e1 with
         VBool true  -> eval renv e2
       | VBool false -> eval renv e3
       | _ -> raise BugTypeInfer )

  | Fn (x,e1) ->  VClos(x,e1,renv)

  | App(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      (match v1 with
         VClos(x,ebdy,renv') ->
           let renv'' = update renv' x v2
           in eval renv'' ebdy

       | VRclos(f,x,ebdy,renv') ->
           let renv''  = update renv' x v2 in
           let renv''' = update renv'' f v1
           in eval renv''' ebdy
       | _ -> raise BugTypeInfer)
  
  | Let(x,e1,e2) ->
      let v1 = eval renv e1
      in eval (update renv x v1) e2

  | LetRec(f,x,e1,e2)  ->
      let renv'= update renv f (VRclos(f,x,e1,renv))
      in eval renv' e2
        
  | Pipe(e1, e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      (match v2 with
         VClos(x, ebdy, renv') ->
           let renv'' = update renv' x v1 in
           eval renv'' ebdy
       | VRclos(f,x,ebdy,renv') ->
           let renv''  = update renv' x v1 in
           let renv''' = update renv'' f v2
           in eval renv''' ebdy
       | _ -> raise BugTypeInfer
      )        

  | Nil -> Vnil
    
  | Cons(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      Vcons(v1, v2)
        
  | PMList(x, xs, e1, e2, e3) ->
      let v1 = eval renv e1 in 
      let v2 = eval renv e2 in 
      (match v1 with
       | Vnil -> v2
       | Vcons (xv, xsv) -> 
           let updated_renv = update (update renv x xv) xs xsv in
           eval updated_renv e3
       | _ -> raise BugTypeInfer)
      
  | Nothing -> Vnothing
    
  | Just(e1) ->
      let v1 = eval renv e1 in
      Vjust(v1)
        
  | PMJust(x,e1,e2,e3) ->
      let v1 = eval renv e1 in 
      let v2 = eval renv e2 in 
      (match v1 with
       | Vnothing -> v2
       | Vjust(xv) -> 
           let updated_renv = update renv x xv in
           eval updated_renv e3
       | _ -> raise BugTypeInfer
      )  
      
  | Left(e1)->
      let v1 = eval renv e1 in
      VLeft(v1)
        
  | Right(e1)->
      let v1 = eval renv e1 in
      VRight(v1)
        
  | PMLR(x,y,e1,e2,e3) ->
      let v1 = eval renv e1 in 
      (match v1 with
       | VLeft(xv) -> 
           let updated_renv = update renv x xv in
           eval updated_renv e2
       | VRight(yv) -> 
           let updated_renv = update renv y yv in
           eval updated_renv e3
       | _ -> raise BugTypeInfer
      )

        (*
          | Hd(e1) ->
            let v1 = eval renv e1 in
            (match v1 with
             | Vnil -> Vnil
             | Vcons(v1,_) -> v1
             | _ -> raise BugTypeInfer
            )
      
          | Tl(e1) ->
            let v1 = eval renv e1 in
            (match v1 with
             | Vnil -> Vnil
             | Vcons(_,v2) -> v2
             | _ -> raise BugTypeInfer
            )
  
          | IsEmpty(e1) ->
            let v1 = eval renv e1 in
            (match v1 with
             | Vnil -> VBool true
             | Vcons(_,_) -> VBool false
             | _ -> raise BugTypeInfer 
            )
  
          | IsNothing(e1) ->
            let v1 = eval renv e1 in
            (match v1 with
             | Vnothing -> VBool true
             | _        -> VBool false
            )
      
          | FromJust(e1,e2) -> 
            let v1 = eval renv e1 in
            let v2 = eval renv e2 in
            (match v1 with
             | Vnothing -> v2
             | Vjust v2 -> v2
             | _ -> raise BugTypeInfer
            )        
      *)
  
      (* Testes aut failed passed *)
exception TestFailed of string

let run_tests () =
  let app0  = App(Fn("x", Binop(Sum, Var "x", Num 10)), Num 5) in
  let app1  = App(Fn("x", Binop(Sum, Var "x", Num 10)), Binop(Sum, Num 1, Num 4)) in
  let pipe0  = Pipe(Num 5, Fn("x", Binop(Sum, Var "x", Num 10))) in
  let pipe1  = Pipe(Bool true, Fn("x", If(Var "x", Num 1, Num 2))) in 
  let pipe2  = Pipe(Bool false, Fn("x", If(Var "x", Num 1, Num 2))) in
  let pml0 = PMList("x", "xs", Cons(Num 1, Cons(Num 2, Cons(Num 3, Nil))), Num 0, Var "x") in
  let pml1 = PMList("x", "xs", Cons(Num 1, Cons(Num 2, Cons(Num 3, Nil))), Num 1, Var "xs") in
  let pml2 = PMList("x", "xs", Nil, Num 1, Num 2) in
  let pml3 = PMList("x", "xs", Nil, Bool true, Bool false) in
  let pml4 = PMList("x", "xs", Cons(Bool true, Nil), Num 1, Num 2) in
  let pml5 = PMList("x", "xs", Nil, Just(Bool true), Just(Bool false)) in
  let pml6 = PMList("x", "xs", Cons(Bool true, Nil), Just(Bool true), Just(Bool false)) in
  let pml7 = PMList("x", "xs", Nil, Nil, Cons(Bool true, Nil)) in
  let pml8 = PMList("x", "xs", Cons(Bool true, Nil), Nil, Cons(Bool true, Nil)) in
  let pml9 = PMList("x", "xs", Nil, Nil, Cons(Left(Bool true), Cons(Right(Num 1) , Nil))) in
  let pml10 = PMList("x", "xs", Cons(Bool true, Nil), Nil, Cons(Left(Num 1), Cons(Right(Bool true) , Nil))) in
  let pml11 = PMList("x", "xs", Cons(Num 1, Nil), Nothing, Just(Num 1)) in
  let pml12 = PMList("x", "xs", Cons(Num 1, Nil), Nothing, Just(Left(Num 1))) in
  let pml13 = PMList("x", "xs", Nil, Nothing, Just(Num 1)) in 
  let tests = [
    ("app0", app0, VNum 15);
    ("app1", app1, VNum 15);
    ("pipe0", pipe0, VNum 15);
    ("pipe1", pipe1, VNum 1);
    ("pipe2", pipe2, VNum 2); 
    ("pml0", pml0, VNum 1);
    ("pml1", pml1, Vcons(VNum 2, Vcons(VNum 3, Vnil)));
    ("pml2", pml2, VNum 1);
    ("pml3", pml3, VBool true);
    ("pml4", pml4, VNum 2);
    ("pml5", pml5, Vjust (VBool true));
    ("pml6", pml6, Vjust (VBool false));
    ("pml7", pml7, Vnil);
    ("pml8", pml8, Vcons(VBool true, Vnil));
    ("pml9", pml9, Vnil);
    ("pml10", pml10, Vcons( VLeft(VNum 1), Vcons(VRight(VBool true), Vnil ) ));
    ("pml11", pml11, Vjust (VNum 1));
    ("pml12", pml12, Vjust (VLeft(VNum 1)));
    ("pml13", pml13, Vnothing);
    (* Adicione mais testes aqui *)
  ] in
  List.iter (fun (test_name, expr, expected_result) ->
      try
        match (eval [] expr) with
        | result when result = expected_result -> Printf.printf "%s passed\n" test_name 
        | _ -> raise (TestFailed (test_name ^ " failed: unexpected result"))
      with
      | TestFailed msg -> print_endline (msg)
      | _ -> ()
    ) tests 
  
      
(*   Testes   *) 

let pmlr0 = PMLR("x", "y", Left(Bool true), Bool true, Bool false)
let pmlr1 = PMLR("x", "y", Left(Num 1), Bool true, Bool false)
let pmlr2 = PMLR("x", "y", Left(Bool true), Num 1, Bool false)
let pmlr3 = PMLR("x", "y", Right(Bool true), Bool true, Bool false)
let pmlr4 = PMLR("x", "y", Right(Bool true), Num 1 , Bool false) 
let pmlr5 = PMLR("x", "y", Nil, Num 1 , Bool false) 
    
let pmj0 = PMJust("x", Nothing, Bool true, Bool false)
let pmj1 = PMJust("x", Nothing, Bool true, Num 1)
let pmj2 = PMJust("x", Just(Num 1), Bool true, Bool false)
let pmj3 = PMJust("x", Just(Bool true), Bool true, Num 1)
let pmj4 = PMJust("x", Nil, Bool true, Num 1) 
let pmj5 = PMJust("x", Nothing, Bool true, Num 1) 
let pmj6 = PMJust("x", Just(Num 1), Bool true, Num 1) 
let pmj7 = PMJust("x", Just(Bool true), Bool true, Num 1)
let pmj8 = PMJust("x", Just(Num 1), Num 2, Var "x") 
  
let t0 = If(Bool true, Num 1, Num 2)
let t1 = If(Bool true, Num 1, Bool false)
let t2 = If(Bool true, Nil, Cons(Num 1, Nil))
let t3 = If(Bool true, Left(Num 1), Right(Bool false))
let t4 = If(Bool true, Nothing, Just(Num 1))
let t5 = If(Bool true, Nothing, Just(Left(Num 1)))
let t6 = If(Bool true, Nothing, Just(Right(Num 1))) 
    

  
    



