%Doctor.Config{
  ignore_paths: [
    "lib/rift/application.ex",
    "lib/rift/mailer.ex",
    "lib/rift/repo.ex",
    "lib/rift_web.ex",
    ~r|lib/rift_web/|,
    ~r|test/support/|
  ],
  min_module_doc_coverage: 40,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 0,
  min_overall_moduledoc_coverage: 100,
  min_overall_spec_coverage: 0,
  exception_moduledoc_required: true,
  struct_type_spec_required: false,
  reporter: Doctor.Reporters.Full,
  raise: false,
  umbrella: false
}
