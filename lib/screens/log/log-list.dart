import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logk8s/models/log_line.dart';



/// A reference to the list of lines.
/// We are using `withConverter` to ensure that interactions with the collection
/// are type-safe.
final linesRef = FirebaseFirestore.instance
    .collection('logs')
    .withConverter<LogLine>(
      fromFirestore: (snapshots, _) => LogLine.fromJson(snapshots.data()!),
      toFirestore: (logLine, _) => logLine.toJson(),
    );

/// The different ways that we can filter/sort lines.
enum LogQuery {
  error,
  warn,
  info,
  http,
  verbose,
  debug,
  silly
}

extension on Query<LogLine> {
  /// Create a firebase query from a [LogQuery]
  Query<LogLine> queryBy(LogQuery query) {
    switch (query) {
      case LogQuery.error:
        return where('level', isEqualTo: 0);

      case LogQuery.warn:
        return where('level', isLessThanOrEqualTo: 1);

      case LogQuery.info:
        return where('level', isLessThanOrEqualTo: 2);

      case LogQuery.http:
        return where('level', isLessThanOrEqualTo: 3);

      case LogQuery.verbose:
        return where('level', isLessThanOrEqualTo: 4);

      case LogQuery.debug:
        return where('level', isLessThanOrEqualTo: 5);

      case LogQuery.silly:
        return where('level', isLessThanOrEqualTo: 6);

      // case LogQuery.namespace:
      //   return where('namespace', arrayContainsAny: ['dev']);

      // case LogQuery.level:
      //   return where('level', isGreaterThanOrEqualTo: LogQuery.level);

      // default:
      //   return where('level', isGreaterThanOrEqualTo: LogQuery.level);

      // case LogQuery.likesAsc:
      // case LogQuery.likesDesc:
      //   return orderBy('likes', descending: query == LogQuery.likesDesc);

      // case LogQuery.year:
      //   return orderBy('year', descending: true);

      // case LogQuery.score:
      //   return orderBy('score', descending: true);
    }
  }
}

class LogList extends StatefulWidget {
  const LogList({Key? key}) : super(key: key);

  @override
  _LogListState createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  LogQuery query = LogQuery.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Firestore Example: LogLines'),

            // This is a example use for 'snapshots in sync'.
            // The view reflects the time of the last Firestore sync; which happens any time a field is updated.
            StreamBuilder(
              stream: FirebaseFirestore.instance.snapshotsInSync(),
              builder: (context, _) {
                return Text(
                  'Latest Snapshot: ${DateTime.now()}',
                  style: Theme.of(context).textTheme.caption,
                );
              },
            )
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<LogQuery>(
            onSelected: (value) => setState(() => query = value),
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: LogQuery.error,
                  child: Text('Filter Error'),
                ),
                const PopupMenuItem(
                  value: LogQuery.warn,
                  child: Text('Filter Warn'),
                ),
                const PopupMenuItem(
                  value: LogQuery.info,
                  child: Text('Filter Info'),
                ),
                const PopupMenuItem(
                  value: LogQuery.http,
                  child: Text('Filter Http'),
                ),
                const PopupMenuItem(
                  value: LogQuery.verbose,
                  child: Text('Filter Verbose'),
                ),
                const PopupMenuItem(
                  value: LogQuery.debug,
                  child: Text('Filter Debug'),
                )
                // const PopupMenuItem(
                //   value: LogQuery.debug,
                //   child: Text('Filter genre Sci-Fi')
                // ),
              ];
            },
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _resetLikes(),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'reset_likes',
                  child: Text('Reset like counts (WriteBatch)'),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<LogLine>>(
        stream: linesRef.queryBy(query).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.requireData;

          return ListView.builder(
            itemCount: data.size,
            itemBuilder: (context, index) {
              return _LogLineItem(
                data.docs[index].data(),
                data.docs[index].reference,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resetLikes() async {
    final lines = await linesRef.get();
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (final line in lines.docs) {
      batch.update(line.reference, {'likes': 0});
    }
    await batch.commit();
  }
}

/// A single log line.
class _LogLineItem extends StatelessWidget {
  const _LogLineItem(this.line, this.reference);

  final LogLine line;
  final DocumentReference<LogLine> reference;

  /// Returns the line level.
  Widget get level {
    return SizedBox(
      width: 100,
      child: Text(line.level),
    );
  }

  /// Returns line details.
  Widget get details {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          k8s,
          network,
          timestamp,
          // Likes(
          //   reference: reference,
          //   currentLikes: line.likes,
          // )
        ],
      ),
    );
  }

  /// Return the line title.
  Widget get timestamp {
    return Text(
      '${line.timestamp}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// Returns network about the line.
  Widget get network {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('IP: ${line.ip}'),
          ),
          Text('Port: ${line.port}'),
        ],
      ),
    );
  }

  List<Widget> get generateK8S {
    return [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Row(
            children: [
                Chip(
                backgroundColor: Colors.lightBlue,
                label: Text(
                  line.namespace,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            ],
          )
        )
    ];
  }

  /// Returns all k8s.
  Widget get k8s {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        children: generateK8S,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          level,
          Flexible(child: details),
        ],
      ),
    );
  }
}
/*
/// Displays and manages the line 'like' count.
class Likes extends StatefulWidget {
  /// Constructs a new [Likes] instance with a given [DocumentReference] and
  /// current like count.
  Likes({
    Key? key,
    required this.reference,
    required this.currentLikes,
  }) : super(key: key);

  /// The reference relating to the counter.
  final DocumentReference<LogLine> reference;

  /// The number of current likes (before manipulation).
  final int currentLikes;

  @override
  _LikesState createState() => _LikesState();
}

class _LikesState extends State<Likes> {
  /// A local cache of the current likes, used to immediately render the updated
  /// likes count after an update, even while the request isn't completed yet.
  late int _likes = widget.currentLikes;

  Future<void> _onLike() async {
    final currentLikes = _likes;

    // Increment the 'like' count straight away to show feedback to the user.
    setState(() {
      _likes = currentLikes + 1;
    });

    try {
      // Update the likes using a transaction.
      // We use a transaction because multiple users could update the likes count
      // simultaneously. As such, our likes count may be different from the likes
      // count on the server.
      int newLikes = await FirebaseFirestore.instance
          .runTransaction<int>((transaction) async {
        DocumentSnapshot<LogLine> line =
            await transaction.get<LogLine>(widget.reference);

        if (!line.exists) {
          throw Exception('Document does not exist!');
        }

        int updatedLikes = line.data()!.likes + 1;
        transaction.update(widget.reference, {'likes': updatedLikes});
        return updatedLikes;
      });

      // Update with the real count once the transaction has completed.
      setState(() => _likes = newLikes);
    } catch (e, s) {
      print(s);
      print('Failed to update likes for document! $e');

      // If the transaction fails, revert back to the old count
      setState(() => _likes = currentLikes);
    }
  }

  @override
  void didUpdateWidget(Likes oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The likes on the server changed, so we need to update our local cache to
    // keep things in sync. Otherwise if another user updates the likes,
    // we won't see the update.
    if (widget.currentLikes != oldWidget.currentLikes) {
      _likes = widget.currentLikes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          iconSize: 20,
          onPressed: _onLike,
          icon: const Icon(Icons.favorite),
        ),
        Text('$_likes likes'),
      ],
    );
  }
}
*/