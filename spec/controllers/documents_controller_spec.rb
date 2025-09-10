require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  let(:valid_svg) { fixture_file_upload('test.svg', 'image/svg+xml') }
  let(:invalid_file) { fixture_file_upload('test.txt', 'text/plain') }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    context 'when no SVG file is provided' do
      it 'returns unprocessable entity status' do
        post :create, params: { svg_file: nil }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('SVG file required')
        expect(json_response['message']).to eq('Please upload valid SVG file')
      end

      it 'returns error when svg_file is empty string' do
        post :create, params: { svg_file: '' }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when invalid file type is provided' do
      it 'returns error for non-SVG file' do
        post :create, params: { svg_file: invalid_file }
        
        expect(response).to have_http_status(:internal_server_error)
        expect(json_response['error']).to eq('Prawn::SVG::Document::InvalidSVGData')
      end
    end

    context 'when valid SVG file is provided' do
      let(:pdf_generator_service) { instance_double(PdfGeneratorService) }
      let(:pdf_url) { 'http://example.com/document.pdf' }

      before do
        allow(PdfGeneratorService).to receive(:new).and_return(pdf_generator_service)
        allow(pdf_generator_service).to receive(:call).and_return(pdf_url)
      end

      it 'calls PdfGeneratorService with correct parameters' do
        expect(PdfGeneratorService).to receive(:new)
          .with(svg_file: kind_of(ActionDispatch::Http::UploadedFile))
          .and_return(pdf_generator_service)
        expect(pdf_generator_service).to receive(:call)

        post :create, params: { svg_file: valid_svg }
      end

      it 'returns created status and pdf_url' do
        post :create, params: { svg_file: valid_svg }
        
        expect(response).to have_http_status(:created)
        expect(json_response['pdf_url']).to eq(pdf_url)
        expect(json_response['message']).to eq('PDF has been successfully created')
      end

      it 'uses success view for blueprint' do
        expect(DocumentBlueprint).to receive(:render)
          .with(hash_including(pdf_url: pdf_url), view: :success)
          .and_return('{"test": "data"}')

        post :create, params: { svg_file: valid_svg }
      end
    end

    context 'when PdfGeneratorService raises an exception' do
      before do
        service_instance = instance_double(PdfGeneratorService)
        allow(PdfGeneratorService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:call).and_raise(StandardError.new('Service failed'))
      end

      it 'returns internal server error status' do
        post :create, params: { svg_file: valid_svg }
        
        expect(response).to have_http_status(:internal_server_error)
        expect(json_response['error']).to eq('StandardError')
        expect(json_response['message']).to eq('Service failed')
      end

      it 'handles different exception types' do
        service_instance = instance_double(PdfGeneratorService)
        allow(PdfGeneratorService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:call).and_raise(Net::OpenTimeout.new('Connection timeout'))

        post :create, params: { svg_file: valid_svg }
        
        expect(response).to have_http_status(:internal_server_error)
        expect(json_response['error']).to eq('Net::OpenTimeout')
        expect(json_response['message']).to eq('Connection timeout')
      end
    end
  end

  describe '#docs_params' do
    it 'permits only svg_file parameter' do
      params = ActionController::Parameters.new(svg_file: valid_svg, extra_param: 'value')
      allow(controller).to receive(:params).and_return(params)
      
      expect(controller.send(:docs_params)).to eq(valid_svg)
    end

    it 'raises ParameterMissing for missing svg_file' do
      params = ActionController::Parameters.new(other_param: 'value')
      allow(controller).to receive(:params).and_return(params)
      
      expect { controller.send(:docs_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
