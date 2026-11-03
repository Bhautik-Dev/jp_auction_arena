import 'package:file_picker/file_picker.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';

abstract interface class TeamLogoPicker {
  Future<TeamLogo?> pickLogo();
}

class FilePickerTeamLogoPicker implements TeamLogoPicker {
  const FilePickerTeamLogoPicker();

  @override
  Future<TeamLogo?> pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected logo could not be read.');
    }
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw StateError('Choose a logo smaller than 5 MB.');
    }

    return TeamLogo(
      fileName: file.name,
      bytes: bytes,
      contentType: file.extension == null
          ? null
          : 'image/${file.extension!.toLowerCase()}',
    );
  }
}
