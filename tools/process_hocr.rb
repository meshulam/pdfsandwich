require 'nokogiri'

CONFIDENCE_REXP = /x_wconf (\d+)/

PAGES_XPATH = "//*[@class='ocr_page']"
PARAS_XPATH = "//*[@class='ocr_par']"
LINES_XPATH = "//*[@class='ocr_line']"
WORDS_XPATH = "//*[@class='ocrx_word']"

PAGEBREAK = "<mbp:pagebreak />" # kindle custom


infile = ARGV[0]

doc = File.open(infile) { |f| Nokogiri::HTML(f) }

def combine_docs(nodes)
  pages = nodes.xpath(PAGES_XPATH)
  root = pages.first.document
  container = pages.first.parent
  container.children = pages

  root
end

def strip_word_tags(nodes)
  nodes.xpath("//*[@class='ocr_line']").each do |line|
    words = line.xpath("./*[@class='ocrx_word']").map do |word|
      confidence = CONFIDENCE_REXP.match(word["title"])[1].to_i

      if confidence > 0 && confidence < 90
        "<b data-confidence=\"#{confidence}\">#{word.text}</b>"
      else
        word.text
      end
    end

    line.children = words.join(' ')
  end
  nodes
end

out = strip_word_tags(combine_docs(doc))
puts out.to_xhtml
