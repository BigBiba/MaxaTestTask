class DocumentsController < ApplicationController
    skip_before_action :verify_authenticity_token
    def  index
    end

    def create
        unless params[:svg_file].present?
            return render json: DocumentBlueprint.render(
                {
                    error: "SVG file required",
                    message: "Please upload valid SVG file"
                }
            ), status: :unprocessable_entity
        end
        service = PdfGeneratorService.new(svg_file: params[:svg_file])
        begin
            pdf_url = service.call
            render json: DocumentBlueprint.render(
                {
                    pdf_url: pdf_url,
                    message: "PDF has been successfully created"
                },
                view: :success
            ), status: :created
        rescue Exception => e
            render json: DocumentBlueprint.render(
                {
                    error: e.class,
                    message: e.message
                }
            ), status: :internal_server_error
        end
    end

    def docs_params
        params.require(:svg_file)
    end
end
