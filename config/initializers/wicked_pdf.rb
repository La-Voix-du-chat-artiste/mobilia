# `WickedPdf.config=` is deprecated in wicked_pdf 2.8.
WickedPdf.configure do |config|
  config.encoding = 'utf8'
  config.page_size = 'A4'
  config.orientation = 'Portrait'
  config.layout = 'application'
  config.margin = {
    top: 10,
    bottom: 10,
    left: 10,
    right: 10
  }
end
