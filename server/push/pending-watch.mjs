export function pendingWatch(kind, newOnly, previousQueue, processDocument) {
  let initial = true;
  return snapshot => {
    if (initial && newOnly) {
      for (const doc of snapshot.docs) previousQueue.add(doc.ref.path);
      console.info('Watching new notifications:', kind, 'existing queued:', snapshot.size);
    } else {
      for (const change of snapshot.docChanges()) {
        previousQueue.delete(change.doc.ref.path);
        if (change.type !== 'removed') processDocument(change.doc, kind);
      }
    }
    initial = false;
  };
}
