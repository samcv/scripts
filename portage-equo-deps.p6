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
    has Str $.value;
    has Str $.revision;
    method set (Str:D $package) {
        $package.match(/ ^
            $<category>=(<[\S]-[/]>+) '/'
            $<name>=(<[\S]-[/]>+) '-'
            $<version>=(<[\S]-[-]>+)
            [ '-' $<revision>=('r'\d+) ]? $/);
        $!key = "$<category>/$<name>";
        $!value = ~$<version>;
        $!revision = ~$<revision> if $<revision>;
        self;
    }
    method package { $!key }
    method packver {
        $!revision ?? "$!key-$!value-$!revision" !! "$!key-$!value";
    }
    method plain { self.packver }
    method Str {
        $!revision
        ?? colored($.key, 'blue') ~ '-' ~ colored($.value, 'green') ~ '-' ~ colored($!revision, 'cyan')
        !! colored($.key, 'blue') ~ '-' ~ colored($.value, 'green');
    }
}
multi sub MAIN
(
Str:D  $query,
Bool:D :$install      = False,
Bool:D :$portage-only = False,
Bool:D :$mask-only    = False,
) {
    my Str:D $result = qqx[equery -C g --depth 1 $query];
    my Str:D @sorted = $result.split("\n\n")>>.trim
            .sort( -> $a is copy, $b is copy {
                #my $b = $^b; my $a = $^a;
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
    my package:D @deps = @sorted>>.subst( /:s '[' \d+ ']' /, '')>>.trim.grep({$_ ne $name}).map({package.new.set: $_ });
    note colored("Deps for package: ", "bold") ~ $pack;
    say '-' x 40 ~ "\n" ~ @deps.join("\n");
    if $mask-only {
        package-mask seperate-package-version($name);
    }
    elsif $install {
        if $portage-only {
            portage-install $name;
        }
        else {
            install $name, @deps;
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
    note colored('>>>> Launching: ', 'bold') ~ colored(@args[0], 'underline bold') ~ ' ' ~ @args[1..*]>>.perl;
}
sub install (Str:D $package, package:D @deps) {
    check-root('install');
    my @args = 'equo', 'install', '--ask', |@deps>>.package;
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
        if .contains($package-pair.key) {
            say "{colored 'Already', 'bold'} see in the file '$_' which matches $package-pair";
        }
    }
    my $mask = $ignore-all-versions
        ?? ""
        !! "<=";
    if bool-prompt colored("Add entry for ", 'bold') ~ "$mask$package-pair into {colored $package-mask-file, 'underline'}?" {
        note "Appending $package-mask-file with $package-pair.key()";
        $package-mask-file.IO.spurt: :append, "$mask$package-pair.plain()\n";
    }
}
multi package-mask (Pair:D $package-pair, Bool:D :$ignore-all-versions = False) {
    package-mask(package.new(key => $package-pair.key, value => $package-pair.value), :$ignore-all-versions);
}
sub portage-install (Str:D $package, Bool:D $ignore-all-versions = False) {
    check-root('portage-install');
    my $package-pair = seperate-package-version($package);
    my @args = 'emerge', '--ask', '>=' ~ $package;
    announce-cmd(@args);
    my $cmd = run |@args;
    my @lines;
    if $cmd.exitcode == 0 {
        package-mask($package-pair);
        note "Resyncing entropy and portage databases";
        my @args = <equo rescue spmsync --ask>;
        announce-cmd(@args);
        my $equo-sync = run |@args;
        say $equo-sync.exitcode;
    }

}
multi sub MAIN (Bool:D :$test) {
    require Test <&is &is-deeply &plan>;
    my $pair = seperate-package-version('media-fonts/fira-mono-3.205');
    is-deeply $pair.key, 'media-fonts/fira-mono';
    is-deeply $pair.value, '3.205';
    my $pack = package.new.set('app-dicts/aspell-en-2016.11.20.0');
    is $pack.key, 'app-dicts/aspell-en', '.key eq app-dicts/aspell-en';
    is $pack.value, '2016.11.20.0', '.value eq 2016.11.20.0';
    is $pack.revision, Str, '.revision is undefined Str';
    is package.new.set('app-dicts/aspell-en-2016.11.20.0').plain, 'app-dicts/aspell-en-2016.11.20.0', 'plain';
}
