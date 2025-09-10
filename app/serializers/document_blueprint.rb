class DocumentBlueprint < Blueprinter::Base
  field :pdf_url
  field :message
  field :error

  view :success do
    fields :pdf_url, :message
    exclude :error
  end

  view :error do
    fields :error, :message
    exclude :pdf_url
  end
end
