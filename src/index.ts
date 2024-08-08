import ejs from "ejs";
import { getContext, helpers, Import, Export, Property, Schema, XtpSchema } from "@dylibso/xtp-bindgen";

function toPascalCase(s: string) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function needsDocumentation(x: Export | Import) {
  if (x.description) return true;
  if (x.input && x.input.description) return true;
  if (x.output && x.output.description) return true;
  return false;
}

function serializableTypes(schema: XtpSchema): string[] {
  const hash : Map<string, boolean> = new Map();

  for (const s of Object.values(schema.schemas)) {
    hash.set(toCSharpType({ $ref: s } as Property), true);
  }

  for (const e of Object.values(schema.exports)) {
    if (e.input) {
      hash.set(toCSharpType((e.input as any) as Property), true);
    }

    if (e.output) {
      hash.set(toCSharpType((e.output as any) as Property), true);
    }
  }

  for (const i of Object.values(schema.imports)) {
    if (i.input) {
      hash.set(toCSharpType((i.input as any) as Property), true);
    }

    if (i.output) {
      hash.set(toCSharpType((i.output as any) as Property), true);
    }
  }

  return Array.from(hash.keys());
}

function toCSharpType(property: Property): string {
  if (property.$ref) return property.$ref.name;
  switch (property.type) {
    case "string":
      if (property.format === "date-time") {
        return "DateTime";
      }
      return "String";
    case "number":
      if (property.format === "float") {
        return "Single";
      }
      if (property.format === "double") {
        return "Double";
      }
      return "long";
    case "integer":
      return "Int32";
    case "boolean":
      return "Boolean";
    case "object":
      return "Object";
    case "array":
      if (!property.items) return "Object[]";
      // TODO this is not quite right to force cast
      return `${toCSharpType(property.items as Property)}[]`;
    case "buffer":
      return "byte[]";
    default:
      throw new Error("Can't convert property to C# type: " + property.type + " of " + property.name);
  }
}

function needsTypeInfo(property: Property): boolean {
  return true;
  // if (property.$ref) return true;

  // if (property.type === "array") {
  //   return needsTypeInfo(property.items as Property);
  // }

  // return false;
}

function typeInfo(property: Property): string {
  if (property.$ref) {
    return toCSharpType(property);
  }

  if (property.type === "array") {
    return typeInfo(property.items as Property) + "Array";
  }

  return toCSharpType(property);

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
    toCSharpType,
    needsTypeInfo,
    isEnum,
    typeInfo,
    serializableTypes,
    needsDocumentation,
    toPascalCase,
  };

  const output = ejs.render(tmpl, ctx, {
    rmWhitespace: true,
  });
  Host.outputString(output);
}
