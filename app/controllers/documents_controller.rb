class DocumentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def index
  end

  def create
    Rails.logger.info "=== DOCUMENTS CREATE STARTED ==="
    Rails.logger.info "Params keys: #{params.keys}"
    Rails.logger.info "SVG file present: #{params[:svg_file].present?}"
    Rails.logger.info "SVG file info: #{params[:svg_file].inspect if params[:svg_file]}"

    unless params[:svg_file].present?
      Rails.logger.warn "SVG file missing in request"
      return render json: DocumentBlueprint.render(
        {
          error: "SVG file required",
          message: "Please upload valid SVG file"
        }
      ), status: :unprocessable_entity
    end

    service = PdfGeneratorService.new(svg_file: params[:svg_file])
    
    begin
      Rails.logger.info "Calling PdfGeneratorService..."
      pdf_url = service.call
      Rails.logger.info "PDF generated successfully: #{pdf_url}"
      
      render json: DocumentBlueprint.render(
        {
          pdf_url: pdf_url,
          message: "PDF has been successfully created"
        },
        view: :success
      ), status: :created
      
    rescue Exception => e
      Rails.logger.error "ERROR in PdfGeneratorService: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      
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
