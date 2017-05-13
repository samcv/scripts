#!/usr/bin/env perl6
=begin pod
=NAME portage-equo installer
=DESCRIPTION
Created for use on Sabayon. Meant for installing packages with emerge (portage) that are
not availible with equo (entropy). Installs all dependencies for the package
with equo and then installs the package with portage. Optionally adds the new
portage installed program to C<package.mask>
=end pod


multi sub MAIN
(
Str:D $query, 
Bool:D :$install = False,
Bool:D :$portage-only = False,
Bool:D :$mask-only = False) {

    my Str:D $result = run(|<equery -C g --depth 1>, $query, :out).out.slurp;
    my Str:D @sorted = $result.split("\n\n")>>.trim
            .sort({ $^a.subst(/^.*?'-'/, '') cmp $^b.subst(/^.*?'-'/, '') });
    if !@sorted {
        note $result;
        exit;
    }
    @sorted = @sorted[0].lines;
    my Str:D $name = @sorted.shift;
    $name .= subst: /':'\s*$/, '';
    note "Deps for package: $name";
    my Str:D @deps = @sorted>>.subst( /:s '[' \d+ ']' /, '')>>.trim;
    say @deps.join(' ');
    if $install {
        if $portage-only {
            portage-install $name;
        }
        else {
            install $name, @deps;
        }
    }
    elsif $mask-only {
        package-mask-file($name);
    }  
}
sub install (Str:D $package, Str:D @deps) {
    if %*ENV<USER> ne 'root' {
        note "You are not root. Can't install";
        exit 1;
    }
    my $cmd = run 'equo', 'install', '--ask', |@deps;
    if $cmd.exitcode == 0 {
        if bool-prompt "Do you want to install it using portage now? N/y" {
            portage-install($package);
        }
    }
}
sub seperate-package-version ($_) {
    .match(/  $<package>=(.*?) '-' $<version>=(<[\S]-[-]>+) $/);
    ~$<package> => ~$<version>;
}
sub bool-prompt (Str:D $line = '') {
    my $prompt = prompt $line ~ '  [y/N]';
    $prompt ~~ /:i << y[es]? >> /;
}

sub portage-install (Str:D $package) {
    my $package-pair = seperate-package-version($package);
    my $cmd = run 'emerge', '--ask', '=' ~ $package;
    if $cmd.exitcode == 0 {
        package-mask-file $package-pair;
        note "Resyncing entropy and portage databases";
        my $equo-sync = run |<equo rescue spmsync --ask>;
        say $equo-sync.exitcode;
    }
}
sub package-mask-file (Str:D $package) {
    my $package-mask = '/etc/entropy/packages/package.mask';
    if bool-prompt "Add entry for $package into $package-mask ?" {
        my $pack-mask = $package-mask.IO.slurp;
        my $slug = seperate-package-version($package).key;
        if $pack-mask.contains($slug) {
            $pack-mask ~~ s/^^ .* $slug .* $$/<=$package/;
            note "Writing over $package-mask and adding <=$package";
            $package-mask.IO.spurt: $pack-mask;
        }
        else {
            my $replacement = $pack-mask.substr(*-1, 1) eq any("\n", "\r\n")
                ?? "<=$package\n"
                !! "\n<=$package\n";
            note "Appending $package-mask with $replacement";
            $package-mask.IO.spurt: :append, "<=$package\n";
        }
    }
}

multi sub MAIN (Bool:D :$test) {
    require Test <&is &is-deeply &plan>;
    my $pair = seperate-package-version('media-fonts/fira-mono-3.205');
    is-deeply $pair.key, 'media-fonts/fira-mono';
    is-deeply $pair.value, '3.205';
}