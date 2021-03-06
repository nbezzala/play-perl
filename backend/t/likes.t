#!/usr/bin/perl


use lib 'lib';
use Play::Test;
use Play::DB qw(db);

use parent qw(Test::Class);
use Test::Fatal;

sub setup :Tests(setup) {
    db->users->collection->remove({});
}

sub like_quest :Tests {
    db->users->add({ login => $_, realms => ['europe'] }) for qw( blah user1 user2 );

    my $quest = db->quests->add({
        team => ['blah'],
        name => 'foo, foo',
        status => 'open',
        realm => 'europe',
    });
    my $id = $quest->{_id};
    db->quests->close($id, 'blah');

    db->quests->like($id, 'user1');
    db->quests->like($id, 'user2');

    # double like is forbidden
    ok exception { db->quests->like($id, 'user2') };

    cmp_deeply
        db->quests->get($id),
        {
            _id => re('^\S+$'),
            ts => re('^\d+$'),
            likes => [
                'user1', 'user2'
            ],
            name => 'foo, foo',
            status => 'closed',
            team => ['blah'],
            author => 'blah',
            realm => 'europe',
        };

    is db->users->get_by_login('blah')->{rp}{europe}, 3;
}

sub self_like_quest :Tests {
    db->users->add({ login => $_, realms => ['europe'] }) for qw( blah );

    my $quest = db->quests->add({
        team => ['blah'],
        name => 'foo, foo',
        status => 'open',
        realm => 'europe',
    });
    my $id = $quest->{_id};

    like exception { db->quests->like($id, 'blah') }, qr/unable to like your own quest/;
}

__PACKAGE__->new->runtests;
