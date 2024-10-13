(*
    UML Diagram Generation Mathematica package
    Copyright (C) 2016  Anton Antonov
*)

(* :Title: UMLDiagramGeneration *)
(* :Author: Anton Antonov *)
(* :Date: 2016-03-13 *)

(* :Package Version: 1.0 *)
(* :Mathematica Version: 10.3.1 *)
(* :Copyright: (c) 2016 Anton Antonov *)
(* :Keywords: UML, Graph, diagram, plot *)
(* :Discussion:

    This package generates UML diagrams according to specified relationships of symbols that represent classes.

    The main reason for programming the package functions came from the need to illustrate the implementations
    of Object-Oriented Design Patterns in Mathematica.

    Consider the following implementation of the Template Method Design Pattern:

      Clear[AbstractClass, ConcreteOne, ConcreteTwo];

      CLASSHEAD = AbstractClass;
      AbstractClass[d_]["Data"[]] := d;
      AbstractClass[d_]["PrimitiveOperation1"[]] := d[[1]];
      AbstractClass[d_]["PrimitiveOperation2"[]] := d[[2]];
      AbstractClass[d_]["TemplateMethod"[]] :=
      CLASSHEAD[d]["PrimitiveOperation1"[]] + CLASSHEAD[d]["PrimitiveOperation2"[]]

      ConcreteOne[d_][s_] := Block[{CLASSHEAD = ConcreteOne}, AbstractClass[d][s]]
      ConcreteOne[d_]["PrimitiveOperation1"[]] := d[[1]];
      ConcreteOne[d_]["PrimitiveOperation2"[]] := d[[1]]*d[[2]];

      ConcreteTwo[d_][s_] := Block[{CLASSHEAD = ConcreteTwo}, AbstractClass[d][s]]
      ConcreteTwo[d_]["PrimitiveOperation1"[]] := d[[1]];
      ConcreteTwo[d_]["PrimitiveOperation2"[]] := d[[3]]^d[[2]];

    Then the corresponding UML diagram can be generated with the commands:

      1. UMLClassGraph[{AbstractClass, ConcreteOne, ConcreteTwo}]

    or

      2. UMLClassGraph[{AbstractClass, ConcreteOne, ConcreteTwo},
                       {AbstractClass -> {"PrimitiveOperation1", "PrimitiveOperation2"}},
                       "Abstract" -> {AbstractClass}, VertexLabelStyle -> "Subsubsection"]


    Here is an example of UML diagram generation without preliminary definitions for the class symbols:

       UMLClassGraph[
         "Parents" -> {Library \[DirectedEdge] Building, Museum \[DirectedEdge] Building, Member \[DirectedEdge] Person},
         "AbstractMethods" -> {Library -> {"Enroll"}, Museum -> {"Enroll"}, Member -> {"Visit"}},
         "RegularMethods" -> {Library -> {"Borrow", "Return"}, Museum -> {"Exhibit"}},
         "Associations" -> {Library \[DirectedEdge] Member, Museum \[DirectedEdge] Member, Client \[DirectedEdge] Building, Client \[DirectedEdge] Person},
         "Aggregations" -> {Library \[DirectedEdge] Book},
         "Abstract" -> {Building, Person},
         "EntityColumn" -> True,
         VertexLabelStyle -> "Text",
         ImageSize -> Large,
         GraphLayout -> "LayeredDigraphEmbedding"]


    The function UMLClassGraph takes all options of Graph.

    The function UMLClassNode can be used to create custom graphs.

    Here is an example of UMLClassNode usage:

      Grid @
        Table[ UMLClassNode[AbstractClass, "Abstract" -> a, "EntityColumn" -> ec],
               {a, {{}, {"PrimitiveOperation1", "PrimitiveOperation2", AbstractClass}}},
               {ec, {False, True}} ]


    Here is an example of PlantUML usage:

       PlantUMLSpec[
         "Parents" -> {"MyPackageClass::D" \[DirectedEdge] "MyPackageClass::C", "MyPackageClass::D" \[DirectedEdge] "MyPackageClass::A",
                       "MyPackageClass::D" \[DirectedEdge] "MyPackageClass::B", "MyPackageClass::C" \[DirectedEdge] "MyPackageClass::A"},
         "AbstractMethods" -> {"MyPackageClass::A" -> {"a1"}, "MyPackageClass::B" -> {"b1"}},
         "RegularMethods" -> {"MyPackageClass::D" -> {"BUILDALL", "b1", "d1"}, "MyPackageClass::C" -> {"BUILDALL", "a1", "c1"}},
         "Abstract" -> {"MyPackageClass::A", "MyPackageClass::B", "MyPackageClass::A"}]

    This file was created using Mathematica Plugin for IntelliJ IDEA.

    Anton Antonov
    2016-03-13

*)

BeginPackage["AntonAntonov`UMLDiagramGeneration`"];

UMLClassNode::usage = "UMLClassNode[classSymbol, opts] creates a Grid object with a class name and its methods \
for the specified class symbol. The option \"Abstract\" can be used to specify abstract class names and methods. \
The option \"EntityColumn\" can be used to turn on and off the explanations column.";

UMLClassGraph::usage = "UMLClassGraph[symbols, abstractMethodsPerSymbol, symbolAssociations, symbolAggregations, opts] \
creates an UML graph diagram for the specified symbols (representing classes) and their relationships. It takes \
as options the options of UMLClassNode and Graph.";

SubValueReferenceRules::usage = "SubValueReferenceRules[symbols] gives a list of directed edge specifications that \
correspond to references within the sub-values of the specified symbols.";

PlantUMLSpec::usage = "PlantUMLSpec[opts__] converts UML-graph spec into PlantUML spec.";

JavaPlantUML::usage = "JavaPlantUML[spec_String, opts___] produces UML diagram images from given specs using a PlantUML Java JAR file.";

PythonWebPlantUML::usage = "PythonPlantUML[spec_String, opts___] produces UML diagram images from given specs using PlantUML web service.";

Begin["`Private`"];


(*********************************************************)
(* UMLClassNode                                          *)
(*********************************************************)

Clear[UMLClassNode];
Options[UMLClassNode] = {
  "AbstractClass" -> False,
  "Abstract" -> {},
  "Regular" -> {},
  "EntityColumn" -> True};

UMLClassNode[classSymbol_Symbol, opts : OptionsPattern[]] :=
    Block[{abstract = OptionValue["Abstract"], regular = OptionValue["Regular"], res},
      res = Cases[SubValues[Evaluate@classSymbol][[All, 1]], _String[___], Infinity];
      UMLClassNode[SymbolName[classSymbol], "Regular" -> Join[regular, Complement[res, abstract]], opts]
    ];

UMLClassNode[classSymbol_String, opts : OptionsPattern[]] :=
    Block[{
      abstractClassQ = TrueQ[OptionValue["AbstractClass"]],
      abstract = OptionValue["Abstract"],
      regular = OptionValue["Regular"],
      enColQ = TrueQ[OptionValue["EntityColumn"]], res, tbl},

      res = Join[abstract, regular];
      res = res /. Map[# -> Style[#, Italic] &, abstract];
      (*Print[{abstract,MemberQ[abstract,classSymbol]}];*)

      If[Length[res] == 0, res = {None}];
      tbl =
          Transpose@{Join[Style[#, Gray] & /@ {"Class", "Methods"},
            Table[SpanFromAbove, {Length[res] - 1}]],
            Join[{Style[ToString[classSymbol], Bold, FontSlant -> If[abstractClassQ, Italic, Plain]]}, res]};
      If[res === {None}, tbl = Most[tbl]];
      Grid[If[enColQ, tbl, tbl[[All, {2}]]],
        Dividers -> {All, {{True, True, False}, -1 -> True}}, Alignment -> Left]
    ];

(*********************************************************)
(* Graph edge functions                                  *)
(*********************************************************)

Clear[UMLInheritanceEdgeFunc];
UMLInheritanceEdgeFunc[pts_List, e_] :=
    Block[{color = Darker[Blend[{Black, Cyan, Blue}]]},
      {
        Arrowheads[{{0.015, 0.85, Graphics[{FaceForm[White], EdgeForm[color], Polygon[{{-1.5, -1}, {1.5, 0}, {-1.5, 1}}]}]}}],
        {color, Arrow[pts]}
      }
    ];

Clear[UMLAssociationEdgeFunc];
UMLAssociationEdgeFunc[pts_List, e_] :=
    Block[{color = Darker[Blend[{Black, Cyan, Blue}]]}, {color, Line[pts]}];

Clear[UMLDirectedAssociationEdgeFunc];
UMLDirectedAssociationEdgeFunc[pts_List, e_] :=
    Block[{color = Darker[Blend[{Black, Cyan, Blue}]]}, {color, Arrow[pts]}];

Clear[UMLAggregationEdgeFunc];
UMLAggregationEdgeFunc[pts_List, e_] :=
    Block[{color = Darker[Blend[{Black, Cyan, Blue}]]},
      {
        Arrowheads[{{0.015, 0.85, Graphics[{FaceForm[White], EdgeForm[color], Polygon[{{-1, -1}, {1, 0}, {-1, 1}, {-3, 0}}]}]}}],
        {color, Arrow[pts]}
      }
    ];

(*********************************************************)
(* SubValueReferenceRules                                *)
(*********************************************************)
Clear[SubValueReferenceRules];

SubValueReferenceRules[symbols : {_Symbol..}] :=
    DeleteCases[#, None] &@
        Flatten@Outer[
          If[#1 =!= #2 && ! FreeQ[Cases[SubValues[#1][[All]],
            RuleDelayed[x_, y_] :> HoldForm[y]], #2], #1 \[DirectedEdge] #2, None] &, symbols, symbols ];

(*********************************************************)
(* UMLClassGraph                                         *)
(*********************************************************)
Clear[UMLClassGraph];

Options[UMLClassGraph] =
    Join[
      {"Parents" -> {}, "AbstractMethods" -> {}, "RegularMethods" -> {}, "Associations" -> {}, "Aggregations" -> {}},
      {"GraphFunction" -> Graph},
      Options[UMLClassNode],
      Options[Graph]
    ];

UMLClassGraph[
  symbols : {(_Symbol | _String) .. },
  abstractMethodsPerSymbol : {_Rule ...} : {},
  symbolAssociations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...} : {},
  symbolAggregations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...} : {},
  opts : OptionsPattern[]] :=
    Block[{grRules},
      grRules = SubValueReferenceRules[symbols];
      UMLClassGraph[grRules, abstractMethodsPerSymbol, symbolAssociations, symbolAggregations, opts]
    ];

UMLClassGraph[
  parents : {DirectedEdge[_Symbol | _String, _Symbol | _String] ..},
  abstractMethodsPerSymbol : {_Rule ...} : {},
  symbolAssociations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...} : {},
  symbolAggregations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...} : {},
  opts : OptionsPattern[]] :=
    UMLClassGraph[
      "Parents" -> parents,
      "AbstractMethods" -> abstractMethodsPerSymbol,
      "RegularMethods" -> {},
      "Associations" -> symbolAssociations,
      "Aggregations" -> symbolAggregations,
      opts];

UMLClassGraph[opts : OptionsPattern[]] :=
    Block[{parents, abstractMethodsPerSymbol, regularMethodsPerSymbol, symbolAssociations, symbolAggregations},

      parents = OptionValue[UMLClassGraph, "Parents"];
      If[ !MatchQ[parents, {DirectedEdge[_Symbol | _String, _Symbol | _String] ..}],
        Echo["The value of the option \"Parents\" is expected to match :" <> ToString[{DirectedEdge[_Symbol | _String, _Symbol | _String] ..}]];
        Return[$Failed]
      ];

      abstractMethodsPerSymbol = OptionValue[UMLClassGraph, "AbstractMethods"];
      If[ !MatchQ[abstractMethodsPerSymbol, {_Rule...}],
        Echo["The value of the option \"AbstractMethods\" is expected to match :" <> ToString[{_Rule...}]];
        Return[$Failed]
      ];

      regularMethodsPerSymbol = OptionValue[UMLClassGraph, "RegularMethods"];
      If[ !MatchQ[regularMethodsPerSymbol, {_Rule...}],
        Echo["The value of the option \"RegularMethods\" is expected to match :" <> ToString[{_Rule...}]];
        Return[$Failed]
      ];

      symbolAssociations = OptionValue[UMLClassGraph, "Associations"];
      If[ !MatchQ[symbolAssociations, {(_DirectedEdge | _UndirectedEdge | _Rule) ...}],
        Echo["The value of the option \"Associations\" is expected to match :" <> ToString[{(_DirectedEdge | _UndirectedEdge | _Rule) ...}]];
        Return[$Failed]
      ];

      symbolAggregations = OptionValue[UMLClassGraph, "Aggregations"];
      If[ !MatchQ[symbolAggregations, {(_DirectedEdge | _UndirectedEdge | _Rule) ...}],
        Echo["The value of the option \"Aggregations\" is expected to match :" <> ToString[{(_DirectedEdge | _UndirectedEdge | _Rule) ...}]];
        Return[$Failed]
      ];

      UMLClassGraphFull[parents, abstractMethodsPerSymbol, regularMethodsPerSymbol, symbolAssociations, symbolAggregations, opts]
    ];

(*********************************************************)
(* UMLClassGraphFull                                     *)
(*********************************************************)

Clear[UMLClassGraphFull];

Options[UMLClassGraphFull] = Options[UMLClassGraph];

UMLClassGraphFull[
  parents : {DirectedEdge[_Symbol | _String, _Symbol | _String] ..},
  abstractMethodsPerSymbol : {_Rule ...},
  regularMethodsPerSymbol : {_Rule ...},
  symbolAssociations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...},
  symbolAggregations : {(_DirectedEdge | _UndirectedEdge | _Rule) ...},
  opts : OptionsPattern[]] :=
    Block[{grRules = parents, symbols, graphFunc},

      graphFunc = OptionValue[UMLClassGraphFull, "GraphFunction"];
      If[ TrueQ[ graphFunc === Automatic || !MemberQ[{Graph, Graph3D}, graphFunc]], graphFunc = Graph ];

      symbols = Union[Flatten[List @@@ Join[parents, symbolAssociations, symbolAggregations]]];

      grRules = Map[
        Which[
          MemberQ[symbolAssociations, #],
          Property[#, EdgeShapeFunction -> UMLDirectedAssociationEdgeFunc],
          MemberQ[symbolAssociations, (UndirectedEdge @@ #) | (UndirectedEdge @@ Reverse[#])],
          Property[#, EdgeShapeFunction -> UMLAssociationEdgeFunc],
          True,
          Property[#, EdgeShapeFunction -> UMLInheritanceEdgeFunc]
        ] &, Union[grRules, symbolAssociations]];

      grRules = Join[grRules, Map[Property[#, EdgeShapeFunction -> UMLAggregationEdgeFunc] &, symbolAggregations]];

      graphFunc[grRules,
        VertexLabels ->
            Map[# ->
                UMLClassNode[#,
                  "EntityColumn" -> OptionValue["EntityColumn"],
                  "Abstract" -> Flatten[Join[{# /. Append[abstractMethodsPerSymbol, _ -> {}]}]],
                  "Regular" -> Flatten[Join[{# /. Append[regularMethodsPerSymbol, _ -> {}]}]],
                  "AbstractClass" -> MemberQ[OptionValue["Abstract"], #]
                ] &,
              symbols],
        FilterRules[{opts}, Options[graphFunc]]]
    ];

(*********************************************************)
(* PlantUMLSpec                                          *)
(*********************************************************)

Clear[PlantUMLSpec];

Options[PlantUMLSpec] = {
  "Parents" -> {},
  "AbstractMethods" -> {},
  "RegularMethods" -> {},
  "Associations" -> {},
  "Aggregations" -> {},
  "Abstract" -> {}
};

PlantUMLSpec[ opts: OptionsPattern[] ] :=
    Block[{UMLClassGraphFull = List,
      parents, abstractMethodsPerSymbol, regularMethodsPerSymbol, symbolAssociations, symbolAggregations,
      abstractClasses,
      aParents, aAbstractMethodsPerSymbol, aRegularMethodsPerSymbol,
      resSpec, lsAllClasses},

      abstractClasses = OptionValue[PlantUMLSpec, "Abstract"];

      (* Process option values with UMLClassGraph *)
      {parents, abstractMethodsPerSymbol, regularMethodsPerSymbol, symbolAssociations, symbolAggregations} = UMLClassGraph[opts][[1;;5]];

      (* Find children per class *)
      aParents = GroupBy[ ReplaceAll[parents, DirectedEdge[x___] :> Rule[x]], First, #[[All, 2]]&];

      (* Find all classes *)
      lsAllClasses = Union @ Flatten[ Join[ List @@@ parents, ReplaceAll[abstractMethodsPerSymbol, Rule[x_,y_] :> x ], ReplaceAll[regularMethodsPerSymbol, Rule[x_,y_] :> x ] ] ];

      aAbstractMethodsPerSymbol = Association[abstractMethodsPerSymbol];
      aAbstractMethodsPerSymbol = StringRiffle[Map[ " {abstract} " <> #&, #], {"\n", "\n", "\n"}]& /@ aAbstractMethodsPerSymbol;

      aRegularMethodsPerSymbol = Association[regularMethodsPerSymbol];
      aRegularMethodsPerSymbol = StringRiffle[Map[ " " <> #&, #], {"\n", "\n", "\n"}]& /@ aRegularMethodsPerSymbol;

      (* Make the UML diagram *)
      resSpec =
          Fold[
            Function[{a, c},
              a <> "\n\n" <> If[ MemberQ[abstractClasses, c], "abstract ", "class "] <> c <>
                  "{" <> Lookup[aAbstractMethodsPerSymbol, c, ""] <> Lookup[aRegularMethodsPerSymbol, c, ""] <> "}"
                  <>
                  If[ KeyExistsQ[aParents, c], "\n" <> StringRiffle[Map[ c <> " --> " <> # &, aParents[c] ], "\n"], ""]
            ], "", lsAllClasses];

      resSpec = StringTrim[resSpec];

      "@startuml\n"  <> resSpec <> "\n@enduml"
    ];

(*********************************************************)
(* JavaPlantUML                                          *)
(*********************************************************)

Clear[JavaPlantUML];

SyntaxInformation[JavaPlantUML] = { "ArgumentsPattern" -> {_, OptionsPattern[] } };

Options[JavaPlantUML] = {
  "Type" -> "svg",
  "PlantUMLJAR" -> "~/PlantUML/plantuml-1.2022.5.jar",
  "ExportPrefix" -> Automatic,
  "ExportDirectory" -> Automatic
};

JavaPlantUML[spec_String, opts : OptionsPattern[]] :=
    Block[{command, type, jarArg, exportPrefix, exportDir, imgResFileName, resShell},

      command =
          StringTemplate["echo \"`spec`\" | java -jar `jarArg` -pipe -t`type` > `imgResFileName`"];

      type = ToLowerCase[OptionValue[JavaPlantUML, "Type"]];
      Which[
        TrueQ[type === Automatic],
        type = "svg",

        !StringQ[type],
        Echo["The value of the option \"Type\" is expected to be a string or Automatic."];
        Return[$Failed]
      ];

      jarArg = OptionValue[JavaPlantUML, "PlantUMLJAR"];
      If[ !FileExistsQ[jarArg],
        Echo["The value of the option \"PlantUMLJAR\" is expected to be a path to an existing Java JAR file."];
        Return[$Failed]
      ];

      exportPrefix = OptionValue[JavaPlantUML, "ExportPrefix"];
      Which[
        TrueQ[exportPrefix === Automatic],
        exportPrefix = StringReplace[DateString["ISODateTime"], ":" -> "-"],

        !StringQ[exportPrefix],
        Echo["The value of the option \"ExportPrefix\" is expected to be a string or Automatic."];
        Return[$Failed]
      ];

      exportDir = OptionValue[JavaPlantUML, "ExportDirectory"];
      Which[
        TrueQ[exportDir === Automatic],
        exportDir = NotebookDirectory[],

        ! ( StringQ[exportPrefix] && DirectoryQ[exportDir]),
        Echo["The value of the option \"ExportDirectory\" is expected to be a string that is a path to a directory that exits."];
        Return[$Failed]
      ];

      imgResFileName = FileNameJoin[{exportDir, exportPrefix <> "-UML-diagram." <> type}];

      resShell = ExternalEvaluate["Shell", command[<|"spec" -> StringReplace[spec, "\"" -> "\\\""], "jarArg" -> jarArg, "type" -> type, "imgResFileName" -> imgResFileName|>]];

      Which[
        ToLowerCase[type] == "svg",
        ResourceFunction["SVGImport"][imgResFileName],

        ToLowerCase[type] == "pdf",
        Import[imgResFileName, "PDF", "PageGraphics"],

        True,
        Import[imgResFileName]
      ]
    ];


(*********************************************************)
(* PythonWebPlantUML                                     *)
(*********************************************************)

Clear[PythonWebPlantUML];

SyntaxInformation[PythonWebPlantUML] = { "ArgumentsPattern" -> {_, _., OptionsPattern[] } };

Options[PythonWebPlantUML] = {"Type" -> "png", "URL" -> "http://www.plantuml.com/plantuml", "Attributes" -> False};

PythonWebPlantUML[spec_String, opts : OptionsPattern[]] :=
    Block[{pythonSession},

      pythonSession =
          If[Length[ExternalSessions["Python"]] == 0,
            StartExternalSession["Python"],
            (*ELSE*)
            ExternalSessions["Python"][[1]]
          ];

      PythonWebPlantUML[pythonSession, spec, opts]
    ];

PythonWebPlantUML[pythonSession_, spec_String, opts : OptionsPattern[]] :=
    Block[{type, url, command, urlForSpec, res, request, resWeb},

      type = ToLowerCase[OptionValue[PythonWebPlantUML, "Type"]];
      Which[
        TrueQ[type === Automatic],
        type = "png",

        !StringQ[type],
        Echo["The value of the option \"Type\" is expected to be a string or Automatic."];
        Return[$Failed]
      ];

      url = OptionValue[PythonWebPlantUML, "URL"];

      ExternalEvaluate[pythonSession, "import plantuml"];

      command = "pumlObj=plantuml.PlantUML(url='" <> url <> "/" <> type <> "/')";

      res = ExternalEvaluate[pythonSession, command];

      urlForSpec = ExternalEvaluate[pythonSession, "pumlObj.get_url(\"\"\"" <> spec <> "\"\"\")"];
      request = HTTPRequest[urlForSpec];
      resWeb = URLRead[request];

      If[TrueQ[resWeb["ContentType"] == "image/png"],
        Import[resWeb],
        (*ELSE*)
        <|"HTTPRequest" -> request, "URL" -> urlForSpec, "URLRead" -> resWeb|>
      ]
    ];

End[]; (* `Private` *)

EndPackage[];