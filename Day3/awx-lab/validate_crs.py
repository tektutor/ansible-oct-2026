"""Validate custom resources against the CRD schemas in a rendered manifest."""
import sys
import jsonschema
import yaml

rendered, crs = sys.argv[1], sys.argv[2:]
schemas = {}
for doc in yaml.safe_load_all(open(rendered)):
    if doc and doc.get("kind") == "CustomResourceDefinition":
        kind = doc["spec"]["names"]["kind"]
        for version in doc["spec"]["versions"]:
            schema = version["schema"]["openAPIV3Schema"]
            schemas[(kind, version["name"])] = schema
print("CRDs:", sorted(k for k, _ in schemas))
for path in crs:
    for doc in yaml.safe_load_all(open(path)):
        if not doc:
            continue
        key = (doc["kind"], doc["apiVersion"].split("/")[1])
        try:
            jsonschema.validate(doc, schemas[key])
            print(f"{path}: {doc['kind']} is valid")
        except jsonschema.ValidationError as error:
            print(f"{path}: {doc['kind']} INVALID: {error.message}")

# The AWX CRDs keep unknown fields, so a misspelled option passes the
# schema and is silently ignored; report fields the schema does not know
for path in crs:
    for doc in yaml.safe_load_all(open(path)):
        if not doc:
            continue
        key = (doc["kind"], doc["apiVersion"].split("/")[1])
        known = schemas[key]["properties"]["spec"].get("properties", {})
        unknown = sorted(set(doc.get("spec", {})) - set(known))
        if unknown:
            print(f"{path}: unknown spec fields: {', '.join(unknown)}")
