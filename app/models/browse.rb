class Browse


  def self.get_auth_list(lett=nil)
    if lett
      auth_list = Author.where("name rlike ?", "^#{lett}.*").order(:name)
    else
      auth_list = Author.order(:name)
    end
  end

  def self.words(id)
    works_arr = Author.get_works(id)
    words = 0
    unless works_arr.empty?
      #need to find the actual work, the array is just ids for works
      works_arr.each do |w| 
        w_row = Work.find(w)
        words = (words + w_row.word_count.to_i) if w_row.word_count
      end
    end
    return words
  end

  def self.author_word_counts
    res = WordCount.order('total_words DESC').take(10)
    top_ten = []
    res.each do |row|
      auth = Author.select(:name).find_by_id(row.auth_id)
      top_ten << [auth.name, row.total_words]
    end
    return top_ten
  end

  def self.auth_type(auth)
    if auth.tlg_id || auth.alt_id =~ /fhg|egf|plg/
      result = "gbutton.png"
    elsif auth.phi_id || auth.stoa_id || auth.alt_id =~ /ota/
      result = "lbutton.png"
    elsif auth.alt_id.split(';').grep(/^\d{4}\w+/).length > 0
        result = "abutton.png"
    else
      result = nil
    end
  end

  def self.word_counter    
    Author.all.each do |auth|
      works_arr = Author.get_works(auth.id)
      words = 0
      unless works_arr.empty?
        #need to find the actual work, the array is just ids for works
        works_arr.each do |w| 
          w_row = Work.find(w)
          words = (words + w_row.word_count.to_i) if w_row.word_count
        end
      end
      if WordCount.find_by_auth_id(auth.id) == nil
        if words > 0
          wc = WordCount.new
          wc.auth_id = auth.id
          wc.total_words = words 
          wc.save
        end
      end
    end
  end

  def word_calculator(works_arr)
    unless works_arr.empty?
      works_arr.each do |w|
        w_row = Work.find(w)
        count = w_row.word_count ? w_row.word_count : 0

      end
    end
  end


end
