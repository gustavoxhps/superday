def logAndExit()
	puts "Something went wrong: \n" + output
	exit $?.exitstatus
end

def getVersionComponents
	output = `agvtool what-marketing-version`
	logAndExit(output) unless $?.success?

	version = output.match(/\d+(\.\d+(\.\d+)?)?/)[0]
	puts "Current version is #{version}"

	components = version.split('.')
	return Integer(components[0]), Integer(components[1]), Integer(components[2])
end

def setVersion(major, minor, maintenance)
	versionString = "#{major}.#{minor}" + (maintenance ?  ".#{maintenance}" : "")
	output = `agvtool new-marketing-version #{versionString}`
	logAndExit(output) unless $?.success?

	puts "Set version to #{versionString}"
	bumpBuild()
end

def bumpBuild
	output = `agvtool next-version -all`
	logAndExit(output) unless $?.success?
	
	lines = output.split("\n")
	version = lines[1].match(/\d+/)[0]
	puts "Bump build to #{version}"
end

def bumpHotfix
	major, minor, maintenance = getVersionComponents()
	maintenance += 1
	setVersion(major, minor, maintenance)
end

def bumpMinor
	major, minor = getVersionComponents()
	minor += 1
	setVersion(major, minor, 0)
end

def bumpMajor
	major, minor = getVersionComponents()
	major += 1
	setVersion(major, 0, 0)
end

verb = ARGV[0]
validCommands = [ "build", "hotfix", "minor", "major"]

commandDescriptions = {
	"build" => "increments build number",
	"hotfix" => "increments maintenance version and build number",
	"minor" => "increments minor version and build number",
	"major" => "increments major version and build number"
} 

commands = {
	"build" => :bumpBuild,
	"hotfix" => :bumpHotfix,
	"minor" => :bumpMinor,
	"major" => :bumpMajor
}

command = commands[verb]

if command
	send(command)
else
	puts "Unknown command '#{verb}'" unless verb == nil
	puts "Usage:"
	
	validCommands.each { |c| puts "bump #{ c } -> #{ commandDescriptions[c] }" }
end