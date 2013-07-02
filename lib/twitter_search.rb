require 'tweetstream'
require 'twitter'
require 'nokogiri'
require 'uuidtools'
require 'httpclient'

class TwitterSearch
  attr_reader :hash_tags
  
  def initialize(params = {})
    @hash_tags = params[:hash_tags]
    authenticate_twitter
  end

  def authenticate_twitter
    Twitter.configure do |config|
      config.consumer_key       = ""
      config.consumer_secret    = ""
      config.oauth_token        = ""
      config.oauth_token_secret = ""
    end
  end

  def fetch
    Twitter.search("#{hash_tags}", count: 1500, result_type: "recent").results.each do |status|
      tweet = clean_tweet(status.text)
      output = get_kaf(tweet)
      puts tweet
    end
  end
  
  def clean_tweet(tweet)
    tweet
      .gsub("RT", "")
      .gsub(/#\S*/, "")
      .gsub(/@\S*/, "")
      .gsub(/http\S*/, "")
      .gsub("  ", " ")
      .rstrip
      .lstrip
  end
  
  
  def get_kaf(tweet)
    client = HTTPClient.new
    
    language_identifier = "http://opener.olery.com/language-identifier"
    res = client.post(language_identifier, :input => tweet, :kaf => true )
    tokenizer = "http://opener.olery.com/tokenizer"
    res = client.post(tokenizer, :input => res.body, :kaf => true)
    pos_tagger = "http://opener.olery.com/POS-tagger"
    res = client.post(pos_tagger, :input => res.body)
    polarity_tagger = "http://opener.olery.com/polarity-tagger"
    res = client.post(polarity_tagger, :input => res.body) 
    ner = "http://opener.olery.com/ner"
    res = client.post(ner, :input => res.body)
    opinion_detector = "http://opener.olery.com/opinion-detector"
    res = client.post(opinion_detector, :input => res.body)
  
    File.open(["tmp/", create_uuid, ".txt"].join, 'w') { |file| file.write(res.body) }
    
  end
  
  def create_uuid
    UUIDTools::UUID.random_create.to_s
  end
  
end