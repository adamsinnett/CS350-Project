#!/usr/bin/env ruby
require 'rspec'
require 'digest/sha1'

BASE = 257
MOD = 1000000007

# Helper function

def max(first,second)
		first > second ? first : second
end

# Brute force method from Levitin p.104

def bruteForceStringSearch(text,search)
	return nil if search.nil? or text.nil?
	n = text.length
	m = search.length
	0.upto(n-m) do |i|
		j = 0
		while (j < m) and text[i+j] == search[j] do
			j += 1
		end
		return i if j==m
	end
	return nil
end

# Brute Force Second ended

# Boyer-Moore String Search from Levitin 259
def boyerMooreStringSearch(text,search,bad_symbol_shift,good_suffix_shift)
	return nil if search.nil? or text.nil?
  text, search = text.unpack('U*'), search.unpack('U*')
    n=0  
    while (n <= text.length - search.length) do  
      m = search.length-1  
      while (search[m] == text[m+n]) do
        return n if m==0  
        m -= 1;  
      end  
      # If not found, shift based on our precomputed tables
      n += max(good_suffix_shift[m], m - bad_symbol_shift[text[n+m]]);
    end
    return nil  
end

# Preprocess the bad symbol table
def bmBadSymbolTable(search)
	return nil if search.nil?
  search = search.unpack('U*')
	# maps the default value to the last char in our table
	bad_char_shift = Hash.new {-1}
	search[0...-2].each_with_index{|char,index| bad_char_shift[char] = index}
	return bad_char_shift
end

# Preprocess the good symbol table
def bmAltGoodSuffixTable(search)
  search = search.unpack('U*')
  goodSuffix = []
  search.length.times do |i|  
      value=0  
      while (value < search.length && !suffixmatch(search, i, value)) do  
        value+=1  
      end  
      goodSuffix[search.length-i-1] = value  
    end  
    return goodSuffix
end
def suffixmatch(search, length, offset)  
  #cut off offset bytes from search  
  search_begin = search.first(search.length-offset)  
      
  #if both search and search_begin contain at least length+1 bytes 
  if (search_begin.length > length)  
    search[-length-1] != search_begin[-length-1]  &&  
    search.last(length) == search_begin.last(length)  
  else  
    search.last(search_begin.length) == search_begin  
  end  
end


# Boyer-Moore Section ended

# KMP Search using the "prefixTable" from CLRS pg. 1004
def knuthMorrisPrattStringSearch(text, search, prefixTable)
  return nil if search.nil? or text.nil?
  n = text.length
  m = search.length
  q = k = 0
  while (k + q < n)
   if search[q] == text[q+k]
      if q == (m - 1)
        return k
      end
      q += 1
    else
      k = k + q - prefixTable[q]
      if prefixTable[q] > -1
        q = prefixTable[q]
      else
        q = 0
      end
    end
  end
end


# Compute our table for KMP
def kmpPrefixTable(search)
  return nil if search.nil?
    prefixTable = [-1,0]
    m = search.length
    q = 2
    k = 0
    while q < m
      if search[q-1] == search[k]
        k += 1
        prefixTable[q] = k
        q += 1
      elsif k > 0
        k = prefixTable[k]
      else
        prefixTable[q] = 0
        q += 1
      end
    end
  return prefixTable
end

# KMP section ended 

# Rabin Karp String Search from CLRS pg. 993
def rabinKarpStringSearch(text, search)
  return nil if search.nil? or text.nil?
  n = text.length
  m = search.length

  searchHash = hash_of(search)
  textHash = hash_of(text[0,m])  

  0.upto(n-m) do |i|
    if textHash == searchHash
      if text[i..i+m-1] == search
        return i
      end
    end
    
    textHash = hash_of(text[i+1..i+m])
  end
  
  nil
end

def rollingHashRabinKarp(text, search)
  return nil if search.nil? or text.nil?
  n = text.length
  m = search.length 

  searchHash = rollinghash(search)
  textHash = rollinghash(text[0,m])  

  0.upto(n-m) do |i|
    if textHash == searchHash
      if text[i..i+m-1] == search
        return i
      end
    end
    textHash = next_hash(text[i+m])
  end
  nil
end

def rollinghash(input)
  return nil if input.nil?
  hash = 0
  n = input.length - 1
    
  0.upto(n) do |i|
    hash += input[i].ord * modulo_exp(n-i) % MOD
    hash = hash % MOD
  end
  @prev_hash = hash
  @prev_input = input
  @highest_power = n
  hash
end

def next_hash(character)
  return nil if character.nil?
  # the leading value of the computed sum
  char_to_subtract = @prev_input.chars.first
  hash = @prev_hash
    
  # subtract the leading value
  hash = hash - (char_to_subtract.ord * BASE**@highest_power)
    
  # shift everything over to the left by 1, and add the
  # new character as the lowest value
  hash = (hash * BASE) + character.ord
  hash = hash % MOD
    
  # trim off the first character
  @prev_input.slice!(0)
  @prev_input << character
  @prev_hash = hash
    
  hash
end

def hash_of(str)
  Digest::SHA1.hexdigest(str)
end

def modulo_exp(power)
  value = 1
  power.times do
    value = (BASE * value) % MOD
  end
  value
end


# Rabin-Karp section ended

#rspec
describe "Brute Force string search" do
  it "should fail when the search key is not in the text" do
    search = "z"
    text = "abcdefghijklmnopqrstuvwxy"
    bruteForceStringSearch(text,search).should == text.index(search)
  end
  it "should find the search key in a trivial search" do
    search = "a"
    text = "a"
    bruteForceStringSearch(text,search).should == text.index(search)
  end
  it "should find the search key in the string" do
    search = "d"
    text = "xyznmlabcdfgh"
    bruteForceStringSearch(text,search).should == text.index(search)
  end
  it "should find a multicharacter search key from the CLRS example" do
    text = "ABC ABCDAB ABCDABCDABDE"
    search = "ABCDABD"
    bruteForceStringSearch(text,search).should == text.index(search)
  end
  it "should find a random key in a pseudorandom text" do
    search = Array.new{rand(256)}
    text = Array.new{64000}
    search.fill {rand(256).to_c}
    text.fill{rand(256).to_c}
    text.insert(rand(64000),search)
    bruteForceStringSearch(text.to_s,search.to_s).should == text.to_s.index(search.to_s)
  end
end

describe "Boyer Moore string search" do
    it "should fail when the search key is not in the text" do
    search = "z"
    text = "abcdefghijklmnopqrstuvwxy"
    boyerMooreStringSearch(text,search,bmBadSymbolTable(search),bmAltGoodSuffixTable(search)).should == text.index(search)
  end
  it "should find the search key in a trivial search" do
    search = "a"
    text = "a"
    boyerMooreStringSearch(text,search,bmBadSymbolTable(search),bmAltGoodSuffixTable(search)).should == text.index(search)
  end
  it "should find the search key in the string" do
    search = "d"
    text = "xyznmlabcdfgh"
    boyerMooreStringSearch(text,search,bmBadSymbolTable(search),bmAltGoodSuffixTable(search)).should == text.index(search)
  end
  it "should find a multicharacter search key from the CLRS example" do
    text = "ABC ABCDAB ABCDABCDABDE"
    search = "ABCDABD"
    boyerMooreStringSearch(text,search,bmBadSymbolTable(search),bmAltGoodSuffixTable(search)).should == text.index(search)
  end
    it "should find a random key in a pseudorandom text" do
    search = Array.new{rand(256)}
    text = Array.new{64000}
    search.fill {rand(256).to_c}
    text.fill{rand(256).to_c}
    text.insert(rand(64000),search)
    boyerMooreStringSearch(text.to_s,search.to_s,bmBadSymbolTable(search.to_s),bmAltGoodSuffixTable(search.to_s)).should == text.to_s.index(search.to_s)
  end
end

describe "Knuth-Morris-Pratt string search" do
  it "should fail when the search key is not in the text" do
    search = "z"
    text = "abcdefghijklmnopqrstuvwxy"
    knuthMorrisPrattStringSearch(text,search, kmpPrefixTable(search)).should == text.index(search)
  end
  it "should find the search key in a trivial search" do
    search = "a"
    text = "a"
    knuthMorrisPrattStringSearch(text,search, kmpPrefixTable(search)).should == text.index(search)
  end
  it "should find the search key in the string" do
    search = "d"
    text = "xdyznmlabcdfgh"
    knuthMorrisPrattStringSearch(text,search, kmpPrefixTable(search)).should == text.index(search)
  end
  it "should find a multicharacter search key from the CLRS example" do
    text = "ABC ABCDAB ABCDABCDABDE"
    search = "ABCDABD"
    knuthMorrisPrattStringSearch(text, search, kmpPrefixTable(search)).should == text.index(search)
  end
    it "should find a random key in a pseudorandom text" do
    search = Array.new{rand(256)}
    text = Array.new{64000}
    search.fill {rand(256).to_c}
    text.fill{rand(256).to_c}
    text.insert(rand(64000),search)
    knuthMorrisPrattStringSearch(text.to_s,search.to_s,kmpPrefixTable(search.to_s)).should == text.to_s.index(search.to_s)
  end
end

describe "Rabin-Karp string search" do
  it "should find the search key in a trivial search" do
    search = "a"
    text = "a"
    rabinKarpStringSearch(text,search).should == text.index(search)
  end
  it "should find the search key in the string" do
    search = "d"
    text = "xyznmlabcdfgh"
    rabinKarpStringSearch(text,search).should == text.index(search)
  end
    it "should find a multicharacter search key from the CLRS example" do
    text = "ABC ABCDAB ABCDABCDABDE"
    search = "ABCDABD"
    rabinKarpStringSearch(text,search).should == text.index(search)
  end
    it "should find a random key in a pseudorandom text" do
    search = Array.new{256}
    text = Array.new{6400}
    search.fill {rand(256).to_c}
    text.fill{rand(256).to_c}
    text.insert(rand(6398),search)
    rabinKarpStringSearch(text.to_s,search.to_s).should == text.to_s.index(search.to_s)
  end
end
describe "Rabin-Karp String Search with rolling hash" do
  it "should find the search key in a trivial search" do
    search = "a"
    text = "bafdafds"
    rollingHashRabinKarp(text,search).should == text.index(search)
  end
  it "should find the search key in the string" do
    search = "gh"
    text = "xyznmlabcdfgh"
    rollingHashRabinKarp(text,search).should == text.index(search)
  end
    it "should find a multicharacter search key from the CLRS example" do
    text = "ABC ABCDAB ABCDABCDABDE"
    search = "ABCDABD"
    rollingHashRabinKarp(text,search).should == text.index(search)
  end
    it "should find a random key in a pseudorandom text" do
    search = Array.new{rand(256)}
    text = Array.new{64000}
    search.fill {rand(256).to_c}
    text.fill{rand(256).to_c}
    text.insert(rand(64000),search)
    rollingHashRabinKarp(text.to_s,search.to_s).should == text.to_s.index(search.to_s)
  end
end