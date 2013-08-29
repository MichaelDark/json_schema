import "root_finder.dart";
import "dart:io";
import "dart:json" as JSON;
import 'package:unittest/unittest.dart';
import "package:json_schema/json_schema.dart";
import "package:pathos/path.dart" as path;
import "package:logging/logging.dart";
import "package:logging_handlers/logging_handlers_shared.dart";

main() {

  ////////////////////////////////////////////////////////////////////////
  // Uncomment to see logging of excpetions
  //
  // Logger.root.onRecord.listen(new PrintHandler());
  // Logger.root.level = Level.INFO;
  // logFormatExceptions = true;

  String here = rootFinder('json_schema');

  Directory testSuiteFolder = 
    new Directory("${here}/test/JSON-Schema-Test-Suite/tests/draft4/invalidSchemas");

  testSuiteFolder = 
    new Directory("${here}/test/JSON-Schema-Test-Suite/tests/draft4");

  var optionals = 
    new Directory(path.joinAll([testSuiteFolder.path, 'optional']));

  var all = testSuiteFolder.listSync()..addAll(optionals.listSync());

  all.forEach((testEntry) {
    if(testEntry is File) {
      group("Validations ${path.basename(testEntry.path)}", () {

        // TODO: add these back or get replacements
        // Skip these for now - reason shown
        if([ 
          'refRemote.json', // seems to require webserver running to vend files
          'format.json',    // optional: add date-time, uri, email, ipv4, ipv6
        ].contains(path.basename(testEntry.path))) return;


        List tests = JSON.parse((testEntry as File).readAsStringSync());
        tests.forEach((testEntry) {
          var schemaData = testEntry["schema"];
          var description = testEntry["description"];
          List validationTests = testEntry["tests"];
          validationTests.forEach((validationTest) {
            String validationDescription = validationTest["description"];
            test("${description} : ${validationDescription}", () {
              var instance = validationTest["data"];
              bool validationResult;
              bool expectedResult = validationTest["valid"];
              var checkResult = expectAsync0(() => expect(validationResult, expectedResult));
              Schema.createSchema(schemaData)
                .then((schema) {
                  validationResult = schema.validate(instance);
                  checkResult();
                });
            });
          });
        });
      });
    }
  });

  test("Schema self validation", () {
    // Pull in the official schema, verify description and then ensure
    // that the schema satisfies the schema for schemas
    String url = "http://json-schema.org/draft-04/schema";
    Schema.createSchemaFromUrl(url)
      .then((schema) {
          expect(schema.schemaMap["description"], "Core schema meta-schema");
          expect(schema.validate(schema.schemaMap), true);
      });
  });

}