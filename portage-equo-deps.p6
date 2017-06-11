#!/usr/bin/env perl6
=NAME portage-equo installer
=DESCRIPTION
Created for use on Sabayon. Meant for installing packages with emerge (portage) that are
not availible with equo (entropy). Installs all dependencies for the package
with equo and then installs the package with portage. Optionally adds the new
portage installed program to C<package.mask>

use Terminal::ANSIColor;
our class package {
    has Str $.key;
    has Str $.category;
    has Str $.package-name;
    has Str $.version;
    has Str $.revision;
    method set (Str:D $package) {
        my @parts = $package.split('/');
        die if @parts.elems != 2;
        $!category = @parts[0];
        my @parts2 = @parts[1].split('-');
        $!revision = @parts2.pop if @parts2.tail.starts-with('r');
        $!version = @parts2.pop;
        $!package-name =  @parts2.join('-');
        self;
    }
    method package { "$!category/$!package-name" }
    method packver {
        $!revision ?? self.package ~ "-$!version-$!revision" !! self.package ~ "-$!version";
    }
    method plain { self.packver }
    method Str {
        [~] colored($!category, 'blue'),
            colored('/', 'bold'),
            colored($!package-name, 'cyan'),
            colored('-', 'bold'),
            colored($!version, 'green'),
            ($!revision ?? colored('-', 'bold') ~ colored($!revision, 'cyan') !! '')
    }
}
multi sub MAIN
(
Str:D $query,
Bool:D :$install = False,
Bool:D :$portage-only = False,
Bool:D :$mask-only = False) {

    my $cmd = run(|<equery -C g --depth 1>, $query, :out, :err);
    my Str:D $result = $cmd.out.slurp;
    my Str:D $stderr = $cmd.err.slurp;
    $*ERR.print: $stderr if $stderr;
    if $cmd.exitcode != 0 or $stderr.contains('!!! No packages matching') {
        exit $cmd.exitcode || 1;
    }
    my Str:D @sorted = $result.split("\n\n")».trim
            .sort( -> $a is copy, $b is copy {
                $b = $b.lines[0].subst(/^.*'-'(.*?)':'?$/, {"$0"});
                $a = $a.lines[0].subst(/^.*'-'(.*?)':'?$/, {"$0"});
                $a = 0 if $a eq '9999';
                $b = 0 if $b eq '9999';
                $b cmp $a;
    });
    if !@sorted {
        note $result;
        exit;
    }
    @sorted = @sorted[0].lines;
    my Str:D $name = @sorted.shift;
    $name .= subst: /':'\s*$/, '';
    my $pack = package.new.set($name);
    my package:D @deps = @sorted».subst( /:s '[' \d+ ']' /, '')».trim.grep({$_ ne $name}).map({package.new.set: $_ });
    note colored("Deps for package: ", "bold") ~ $pack;
    say '-' x 40 ~ "\n" ~ @deps.join("\n");
    if $mask-only {
        package-mask $pack;
    }
    elsif $install {
        if $portage-only or !@deps {
            portage-install $pack;
        }
        else {
            install $pack, @deps;
        }
    }
}
sub check-root (Str:D $verb) {
    if %*ENV<USER> ne 'root' {
        note colored("You are not root. Can't $verb", 'bold underline');
        exit 1;
    }
}
sub announce-cmd (@args) {
    note colored('>>>> Launching: ', 'bold') ~ colored(@args[0], 'underline bold') ~ ' ' ~ @args[1..*]».perl;
}
sub install (package:D $package, package:D @deps) {
    check-root('install');
    my @args = 'equo', 'install', '--ask', |@deps».package;
    announce-cmd(@args);
    my $cmd = run |@args;
    if $cmd.exitcode == 0 {
        if bool-prompt "Do you want to install it using portage now?" {
            portage-install($package);
        }
    }
}
sub seperate-package-version ($_) {
    .match(/  $<package>=(.*?) '-' $<version>=(<[\S]-[-]>+) $/);
    ~$<package> => ~$<version>;
}
sub bool-prompt (Str:D $line = 'prompt: ') {
    state $yn = [~] colored(' [', 'bold'), colored('y', 'green'), '/', colored('N', 'red'), colored('] ', 'bold');
    my $prompt = prompt $line ~ $yn;
    $prompt ~~ /:i << y[es]? >> /;
}
multi package-mask (package:D $package-pair, Bool:D :$ignore-all-versions = False) {
    check-root('mask');
    my $package-mask-file = '/etc/entropy/packages/package.mask';
    for $package-mask-file.IO.lines {
        if .contains($package-pair.package) {
            say "{colored 'Already', 'bold'} see in the file '$_' which matches $package-pair";
        }
    }
    my $mask = $ignore-all-versions
        ?? ""
        !! "<=";
    if bool-prompt colored("Add entry for ", 'bold') ~ "$mask$package-pair into {colored $package-mask-file, 'underline'}?" {
        note "Appending $package-mask-file with $package-pair.package()";
        $package-mask-file.IO.spurt: :append, "$mask$package-pair.plain()\n";
    }
}
sub portage-install (package:D $package, Bool:D $ignore-all-versions = False) {
    check-root('portage-install');
    my @args = 'emerge', '--ask', '>=' ~ $package.packver;
    announce-cmd(@args);
    my $cmd = run |@args;
    my @lines;
    if $cmd.exitcode == 0 {
        package-mask($package);
        note "Resyncing entropy and portage databases";
        my @args = <equo rescue spmsync --ask>;
        announce-cmd(@args);
        my $equo-sync = run |@args;
        say $equo-sync.exitcode;
    }
}

multi sub MAIN (Bool:D :$test) {
    require Test <&is &is-deeply &plan &done-testing>;
    my $pair = seperate-package-version('media-fonts/fira-mono-3.205');
    is-deeply $pair.key, 'media-fonts/fira-mono';
    is-deeply $pair.value, '3.205';
    my $pack = package.new.set('app-dicts/aspell-en-2016.11.20.0');
    is $pack.package-name, "aspell-en", "package-name is aspell-en";
    is $pack.package, 'app-dicts/aspell-en', "package-name is aspell-en";
    is $pack.version, "2016.11.20.0", "version is 2016.11.20.0";
    is $pack.category, "app-dicts", "category is app-dicts";
    is $pack.revision, Str, '.revision is undefined Str';
    is package.new.set('app-dicts/aspell-en-2016.11.20.0').plain, 'app-dicts/aspell-en-2016.11.20.0', 'plain';
    my $jre = package.new.set('virtual/jre-1.8.0-r1');
    is $jre.package, 'virtual/jre', 'package is virtual/jre';
    is $jre.packver, 'virtual/jre-1.8.0-r1';
    is $jre.category, 'virtual', 'category is virtual';
    is $jre.package-name, 'jre', 'package-name is jre';
    is $jre.version, '1.8.0', 'package-name is jre';
    say $jre.Str;
    my @array = [
    ['dev-libs', 'openssl', '1.0.2k', ''],
    ];
    my $ssl = package.new.set('dev-libs/openssl-1.0.2k');
    is $ssl.category, @array[0][0];
    done-testing;
}
