require 'sinatra'
require 'json'
require 'redcarpet'


# Read the configuration from the config.json file
$config = JSON.parse(File.read(File.expand_path('config.json', __dir__)));

# Set sinatra options
set :bind, $config['interface'] || '0.0.0.0'
set :port, $config['port'] || ENV['PORT']
# Enable sessions
set :sessions, true

before do
    content_type 'application/json'
end

renderer = Redcarpet::Render::HTML.new(render_options={})
$markdown = Redcarpet::Markdown.new(renderer, extensions={});

def get_post_data(post_name)
    post = File.read(post_name)
    if $config['render']
        post = $markdown.render(post)
    end
    return {title:File.basename(post_name, ".md"), content:post, timestamp: (File.mtime(post_name).to_i)}
end

def get_abs_path(file)
    return File.expand_path(file, __dir__)
end

get '/' do
  return {data:'Available methods', error:nil}
end

get '/post/:name' do
    postpath = get_abs_path(File.join($config['dir'], params[:name] + '.md'))
    unless File.exist?(postpath)
        status 404
        return 'Post not found'
    end
    return get_post_data(postpath).to_json
end

get '/page/:num' do
    pageNum = params[:num].to_i
    # Get all the posts names
    posts = Dir.glob(get_abs_path(File.join($config['dir'], '*md'))).sort_by{|f| test(?M, f)}.reverse
    if posts.none?
        status 404
        return 'No posts found'
    end
    if pageNum == 0
        pageNum = 1
    end
    start = (pageNum-1) * $config['pageSize']
    finish = start + $config['pageSize']
    # Return the posts in the range in JSON format
    if posts.length >= start
        return posts[start..finish].map { |elm| get_post_data(elm) }.to_json
    end
    status 404
    return 'No posts'
end

get '/all' do
    # Get all the posts
    posts = Dir.glob(get_abs_path(File.join($config['dir'], '*md'))).sort_by{|f| test(?M, f)}.reverse
    # Return the posts as an array of post data in JSON
    return posts.map { |elm| get_post_data(elm) }.to_json
end

get '/count' do
    # Return the count of total posts
    return Dir.glob(get_abs_path(File.join($config['dir'], '*.md'))).count.to_s
end

post '/admin/publish' do
    # Use only the basename for security reasons
    postname = File.basename(params[:post][:filename])
    file = params[:post][:tempfile]
    # Write the post to the posts dir
    File.open(get_abs_path(File.join($config['dir'], postname)), 'w') do |f|
        f.write(file.read)
    end

end

post '/auth' do
   session[:auth] = true
end

delete '/post/:name' do
    # Again, use basename for security reasons
    postname = File.basename(params[:name]) + '.md'
    # Delete the file
    File.delete(get_abs_path(File.join($config['dir'], postname)))
end
