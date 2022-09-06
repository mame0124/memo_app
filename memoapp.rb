require "sinatra"
require "sinatra/reloader"
require "json"
require "SecureRandom"

get "/memos" do
  @memo_infos = IO.readlines('memo.json').map {|memo_info| JSON.parse(memo_info, symbolize_names: true)}
  erb :index
end

get "/memos/new" do
  erb :new
end

get "/memos/:id" do
  @id = params[:id]
  @title = ''
  @memo = ''
  IO.readlines('memo.json').each {|memo_info|
    if JSON.parse(memo_info, symbolize_names: true)[:id] == @id
      @title = JSON.parse(memo_info, symbolize_names: true)[:title]
      @memo = JSON.parse(memo_info, symbolize_names: true)[:memo].gsub(/\n|\r\n|\r/, '<br>')
    end
  }
  erb :show
end

get "/memos/:id/edit" do
  @id = params[:id]
  @title = ''
  @memo = ''
  IO.readlines('memo.json').each {|memo_info|
    if JSON.parse(memo_info, symbolize_names: true)[:id] == @id
      @title = JSON.parse(memo_info, symbolize_names: true)[:title]
      @memo = JSON.parse(memo_info, symbolize_names: true)[:memo]
    end
  }
  erb :edit
end

post "/memos" do
  new_memo_info = params
  unless new_memo_info["title"].match?(/[^ ]+/)
    new_memo_info["title"] = "No title"
  end
  new_memo_info["id"] = SecureRandom.hex(5)
  IO.write('memo.json', "#{new_memo_info.to_json}\n", mode: "a")
  redirect 'http://localhost:4567/memos'
end

delete "/memos/:id" do
  json = []
  IO.readlines('memo.json').each {|memo_info|
    if JSON.parse(memo_info, symbolize_names: true)[:id] != params[:id]
      json << JSON.parse(memo_info,symbolize_names: true)
    end
  }
  IO.write('memo.json',json.map{|x| "#{x.to_json}\n"}.join )
  redirect 'http://localhost:4567/memos'
end

patch "/memos/:id" do
  json = []
  IO.readlines('memo.json').each {|memo_info|
    if JSON.parse(memo_info, symbolize_names: true)[:id] == params[:id]
      params.delete("_method")
      json << params
    elsif
      json << JSON.parse(memo_info, symbolize_names: true)
    end
  }
  IO.write('memo.json',json.map{|x| "#{x.to_json}\n"}.join ) 
  redirect 'http://localhost:4567/memos'
end

