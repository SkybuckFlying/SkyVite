unit Common.Db.XLevelDB.Doc;

interface
uses
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Iter,
  Common.DB.XLevelDB.DB.Snapshot,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version;

{
  Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
  All rights reserved.

  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.

  Package leveldb provides implementation of LevelDB key/value database.

  Create or open a database:

	// The returned DB instance is safe for concurrent use. Which mean that all
	// DB's methods may be called concurrently from multiple goroutine.
	db, err := leveldb.OpenFile("path/to/db", nil)
	...
	defer db.Close()
	...

  Read or modify the database content:

	// Remember that the contents of the returned slice should not be modified.
	data, err := db.Get([]byte("key"), nil)
	...
	err = db.Put([]byte("key"), []byte("value"), nil)
	...
	err = db.Delete([]byte("key"), nil)
	...

  Iterate over database content:

	iter := db.NewIterator(nil, nil)
	for iter.Next() {
		// Remember that the contents of the returned slice should not be modified, and
		// only valid until the next call to Next.
		key := iter.Key()
		value := iter.Value()
		...
	}
	iter.Release()
	err = iter.Error()
	...

  Iterate over subset of database content with a particular prefix:
	iter := db.NewIterator(util.BytesPrefix([]byte("foo-")), nil)
	for iter.Next() {
		// Use key/value.
		...
	}
	iter.Release()
	err = iter.Error()
	...

  Seek-then-Iterate:

 	iter := db.NewIterator(nil, nil)
 	for ok := iter.Seek(key); ok; ok = iter.Next() {
 		// Use key/value.
 		...
 	}
 	iter.Release()
 	err = iter.Error()
 	...

  Iterate over subset of database content:

 	iter := db.NewIterator(&util.Range{Start: []byte("foo"), Limit: []byte("xoo")}, nil)
 	for iter.Next() {
 		// Use key/value.
 		...
 	}
 	iter.Release()
 	err = iter.Error()
 	...

  Batch writes:

	batch := new(leveldb.Batch)
	batch.Put([]byte("foo"), []byte("value"))
	batch.Put([]byte("bar"), []byte("another value"))
	batch.Delete([]byte("baz"))
	err = db.Write(batch, nil)
	...

  Use bloom filter:

	o := &opt.Options{
		Filter: filter.NewBloomFilter(10),
	}
	db, err := leveldb.OpenFile("path/to/db", o)
	...
	defer db.Close()
	...
}

implementation

end.
