[
  # The success typing for marks_to_styles shows a struct literal with specific constant values
  # but the spec correctly uses DocSpec.Spec.Styles.t() which is the intended type.
  {"lib/docspec/core/tiptap/reader.ex", :invalid_contract},

  # The success typing for read_asset! shows a struct literal with specific constant values
  # but the spec correctly uses DocSpec.Spec.Asset.t() which is the intended type.
  {"lib/docspec/core/docx/reader/post_process.ex", :invalid_contract},

  # The success typing for write_resource shows struct literals with specific constant values
  # but the spec correctly uses the intended types (dialyzer sees "call" errors due to union specs).
  {"lib/docspec/core/blocknote/writer.ex", :call}
]
