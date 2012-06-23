# myapp.rb
# If you're using bundler, you will need to add this
require 'bundler/setup'
require 'sinatra'
require 'git'

set :public_folder, File.dirname(__FILE__) + '/static'
PAGES_LOCATION='pages'


get '/' do
  redirect '/wiki/index'
end

get %r{/wiki(/.*)} do |path|
  @path,@filename = filename_path(path)
  from_home=""
  @path_segments = path.split('/').drop(1).collect do |e|
    from_home += "/" + e
    {basename: e, path: from_home}
  end
  @page = @path_segments.slice!(-1)
  if @filename =~ /index\.md/
    @page[:is_a_dir] = true
  end
  @page[:content] = File.open(@filename, 'rb') { |f| f.read }
  haml :main
end

post %r{/wiki(/.*)} do |path|
  @path,filename = filename_path(path)
  File.open(filename, 'w') { |f| f.write(params[:content]) }
  git_commit(filename)
  redirect "/wiki#{@path}"
end

def filename_path(path)
  path += 'index' if path =~ /\/$/
  filename = "#{PAGES_LOCATION}#{path}.md"
  init_file(filename)
  [path,filename]
end

def init_file(fullpath)
  dname = File.dirname(fullpath)
  Dir.mkdir(dname) unless Dir.exists?(dname)
  File.open(fullpath, "w") {} unless File.exists?(fullpath)
end

def git_commit(fullpath)
  git_check_init
  git = Git.open(File.expand_path(PAGES_LOCATION))
  git.add(File.expand_path(fullpath))
  git.commit(Time.now.to_s)
end

def git_check_init
  unless Dir.exists?(File.expand_path(PAGES_LOCATION+'/.git'))
    Git.init(File.expand_path(PAGES_LOCATION))
  end
end

