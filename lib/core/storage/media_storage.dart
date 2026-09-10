abstract final class MediaStorage {
  static const checkinBucket = 'checkin-media';
  static const profileBucket = 'profile-media';

  static const maxCheckinPhotoBytes = 5 * 1024 * 1024;
  static const maxProfilePhotoBytes = 1024 * 1024;
}
