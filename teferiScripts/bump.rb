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
validCommands = ["hotfix", "minor", "major"]

commandDescriptions = {
	"hotfix" => "increments maintenance version",
	"minor" => "increments minor version and resets hotfix",
	"major" => "increments major version and resets minor and hotfix"
}

commands = {
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
