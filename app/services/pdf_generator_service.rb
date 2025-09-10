class PdfGeneratorService
    include Prawn::Measurements

    def initialize(svg_file:)
      @svg_file = svg_file
      @tmp_png_path = Rails.root.join("tmp", "temp_#{SecureRandom.hex}.png")
      @filename = "pdf_#{SecureRandom.hex}.pdf"
      @pdf_path = Rails.root.join("public", @filename)
    end

    def call
        generate_pdf
        @filename
    ensure
        File.delete(@tmp_png_path) if File.exist?(@tmp_png_path)
    end

    private

    WATERMARK_TEXT = "NIKITA"
    WATERMARK_COLOR = "808080"
    MARGIN_BEFORE = 1 # cm
    MARGIN_AFTER = 1 # cm

    def generate_pdf
        svg_content = File.read(@svg_file)
        temp_pdf = Prawn::Document.new
        svg_info = temp_pdf.svg(svg_content)

        margin_pt = cm2pt(MARGIN_AFTER)
        page_width = svg_info[:width] + margin_pt * 2
        page_height = svg_info[:height] + margin_pt * 2
        Prawn::Document.generate(
            @pdf_path,
            page_size: [ page_width, page_height ],
            margin: margin_pt
            ) do |pdf|
            pdf.svg IO.read(@svg_file)
            pdf.transparent(0.2) do
                pdf.fill_color WATERMARK_COLOR
                0.step(pdf.bounds.height + 80, 80) do |y|
                0.step(pdf.bounds.width + 200, 200) do |x|
                    offset = y % 160 == 0 ? 0 : 100

                    pdf.text_box WATERMARK_TEXT,
                        at: [ x + offset, y ],
                        size: 14,
                        rotate: 30,
                        width: 150,
                        height: 15,
                        align: :center,
                        valign: :center
                    end
                end
            end
        end
    end
end
