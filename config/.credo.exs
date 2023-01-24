%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        {Credo.Check.Readability.ModuleDoc, files: %{excluded: ["test"]}}
      ]
    }
  ]
}
