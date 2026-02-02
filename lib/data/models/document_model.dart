class Document {
  final int? id;
  final String docType;
  final String filePath;
  final String issueDate;
  final String expiryDate;
  final String status;

  Document({
    this.id,
    required this.docType,
    required this.filePath,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doc_type': docType,
      'file_path': filePath,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'status': status,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      docType: map['doc_type'],
      filePath: map['file_path'],
      issueDate: map['issue_date'],
      expiryDate: map['expiry_date'],
      status: map['status'],
    );
  }
}
