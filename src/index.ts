import ejs from "ejs";
import { getContext, helpers, Import, Export, Property, Schema, XtpSchema, XtpNormalizedType, ArrayType, BufferType, ObjectType, EnumType, MapType } from "@dylibso/xtp-bindgen";

function toPascalCase(s: string) {
  const cap = s.charAt(0).toUpperCase();
  if (s.charAt(0) === cap) {
    return s;
  }

  const pub = cap + s.slice(1);
  return pub;
}

function csharpName(s: string) {
  return toPascalCase(s);
}

function needsDocumentation(x: Export | Import) {
  if (x.description) return true;
  if (x.input && x.input.description) return true;
  if (x.output && x.output.description) return true;
  return false;
}

function serializableTypes(schema: XtpSchema): string[] {
  const hash: Map<string, boolean> = new Map();

  for (const s of Object.values(schema.schemas)) {
    hash.set(toCSharpTypeX(s.xtpType), true);
  }

  for (const e of Object.values(schema.exports)) {
    if (e.input) {
      hash.set(toCSharpTypeX(e.input.xtpType), true);
    }

    if (e.output) {
      hash.set(toCSharpTypeX(e.output.xtpType), true);
    }
  }

  for (const i of Object.values(schema.imports)) {
    if (i.input) {
      hash.set(toCSharpTypeX(i.input.xtpType), true);
    }

    if (i.output) {
      hash.set(toCSharpTypeX(i.output.xtpType), true);
    }
  }

  return Array.from(hash.keys());
}

function toCSharpTypeX(type: XtpNormalizedType): string {
  if (!type) {
    return "void";
  }
  
  switch (type.kind) {
    case "string":
      return "String";
    case "int32":
      return "Int32";
    case "int64":
      return "Int64";
    case "float":
      return "Single";
    case "double":
      return "Double";
    case "boolean":
      return "bool";
    case "date-time":
      return "DateTime";
    case "byte":
      return "byte";
    case "array":      
      const arrayType = type as ArrayType

      // TODO: double check this
      if (arrayType.elementType.kind === 'object') {
        const objType = arrayType.elementType as ObjectType;
        if (!objType.name) {
          return "JsonArray";
        }
      }

      return toCSharpTypeX(arrayType.elementType) + "[]";
    case "buffer":
      return "byte[]";
    case "object":
      const objType = type as ObjectType;
      if (objType.properties.length === 0) {
        return "JsonNode";
      }

      return csharpName(objType.name);
    case "enum":
      return csharpName((type as EnumType).name);
    case "map":
      const { keyType, valueType } =  type as MapType
      return `Dictionary<${toCSharpTypeX(keyType)}, ${toCSharpTypeX(valueType)}>`;
    default:
      throw new Error("Can't convert type to C# type: " + JSON.stringify(type));
  }
}

function typeInfo(type: XtpNormalizedType): string {
 if (type.kind === 'array') {
  return typeInfo((type as ArrayType).elementType) + 'Array';
 }

 return toCSharpTypeX(type);
}

function isEnum(schema: Schema): boolean {
  if (!schema.enum) return false;
  return schema.enum.length > 0;
}

export function render() {
  const tmpl = Host.inputString();
  const ctx = {
    ...helpers,
    ...getContext(),
    toCSharpTypeX,
    isEnum,
    serializableTypes,
    needsDocumentation,
    csharpName,
  };

  const output = ejs.render(tmpl, ctx, {
    rmWhitespace: true,
  });
  Host.outputString(output);
}
