%% Grammar for Turtle as specified in https://www.w3.org/TR/2014/REC-n-triples-20140225/

Nonterminals turtleDoc statement directive prefixID base sparqlPrefix sparqlBase
  triples predicateObjectList objectList blankNodePropertyList
  verb subject predicate object collection collection_elements
  literal numericLiteral rdfLiteral booleanLiteral iri prefixedName blankNode.

Terminals prefix_ns prefix_ln iriref blank_node_label anon
  string_literal_quote langtag integer decimal double boolean
  '.' ';' ',' '[' ']' '(' ')' '^^' '@prefix' '@base' 'PREFIX' 'BASE' 'a' .

Rootsymbol turtleDoc.


turtleDoc -> statement : ['$1'] .
turtleDoc -> statement turtleDoc : ['$1' | '$2'] .

statement -> directive    : {directive, '$1'} .
statement -> triples '.'  : {triples, '$1'} .

directive -> prefixID     : '$1' .
directive -> sparqlPrefix : '$1' .
directive -> base         : '$1' .
directive -> sparqlBase   : '$1' .

prefixID      -> '@prefix' prefix_ns iriref '.' : {prefix, '$2', to_uri_string('$3')} .
sparqlPrefix  -> 'PREFIX' prefix_ns iriref      : {prefix, '$2', to_uri_string('$3')} .
sparqlBase    -> 'BASE' iriref                  : {base, to_uri_string('$2')} .
base          -> '@base' iriref '.'             : {base, to_uri_string('$2')} .

triples -> subject predicateObjectList                : { '$1', '$2' }.
triples -> blankNodePropertyList predicateObjectList  : { '$1', '$2' }.
triples -> blankNodePropertyList                      : '$1'.

predicateObjectList -> verb objectList     : [{'$1', '$2'}] .
predicateObjectList -> verb objectList ';' : [{'$1', '$2'}] .
predicateObjectList -> verb objectList ';' predicateObjectList : [{'$1', '$2'} | '$4'] .

objectList -> object                : ['$1'] .
objectList -> object ',' objectList : ['$1' | '$3'] .

blankNodePropertyList -> '[' predicateObjectList ']' : {blankNodePropertyList, '$2'} .

verb      -> 'a'                    : rdf_type() .
verb      -> predicate              : '$1' .
subject   -> iri                    : '$1' .
subject   -> blankNode              : '$1' .
subject   -> collection             : '$1' .
predicate -> iri                    : '$1' .
object    -> iri                    : '$1' .
object    -> blankNode              : '$1' .
object    -> collection             : '$1' .
object    -> blankNodePropertyList  : '$1' .
object    -> literal                : '$1' .

collection -> '(' ')'                     : {collection, []} .
collection -> '(' collection_elements ')' : {collection, '$2'} .
collection_elements -> object                     : ['$1'] .
collection_elements -> object collection_elements : ['$1' | '$2'] .

prefixedName -> prefix_ln : '$1' .
prefixedName -> prefix_ns : '$1' .

literal -> rdfLiteral     : '$1' .
literal -> numericLiteral : '$1' .
literal -> booleanLiteral : '$1' .
rdfLiteral -> string_literal_quote '^^' iriref : to_literal('$1', {datatype, to_uri('$3')}) .
rdfLiteral -> string_literal_quote langtag     : to_literal('$1', {language, to_langtag('$2')}) .
rdfLiteral -> string_literal_quote '@prefix'   : to_literal('$1', {language, to_langtag('$2')}) .
rdfLiteral -> string_literal_quote '@base'   : to_literal('$1', {language, to_langtag('$2')}) .
rdfLiteral -> string_literal_quote             : to_literal('$1') .
numericLiteral -> integer : to_literal('$1') .
numericLiteral -> decimal : to_literal('$1') .
numericLiteral -> double  : to_literal('$1') .
booleanLiteral -> boolean : to_literal('$1') .

iri -> iriref       : to_uri('$1') .
iri -> prefixedName : '$1' .

blankNode -> blank_node_label : to_bnode('$1') .
blankNode -> anon             : {anon} .


Erlang code.

to_uri_string(IRIREF) -> 'Elixir.RDF.Serialization.ParseHelper':to_uri_string(IRIREF) .
to_uri(IRIREF) -> 'Elixir.RDF.Serialization.ParseHelper':to_absolute_or_relative_uri(IRIREF) .
to_bnode(BLANK_NODE) -> 'Elixir.RDF.Serialization.ParseHelper':to_bnode(BLANK_NODE).
to_literal(STRING_LITERAL_QUOTE) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE).
to_literal(STRING_LITERAL_QUOTE, Type) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE, Type).
to_langtag(LANGTAG) -> 'Elixir.RDF.Serialization.ParseHelper':to_langtag(LANGTAG).
rdf_type() -> 'Elixir.RDF.Serialization.ParseHelper':rdf_type().
