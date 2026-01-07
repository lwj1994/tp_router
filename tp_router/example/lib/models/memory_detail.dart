class MemoryDetail {
  final String id;
  final String content;

  const MemoryDetail({
    this.id = 'default',
    this.content = 'Default Content',
  });

  @override
  String toString() => 'MemoryDetail(id: $id, content: $content)';
}
