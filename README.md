# Project 3 - *BeRealClone*

Submitted by: **Aaryan Panthi**

**BeRealClone** is an app that recreates the core BeReal experience - a social photo-sharing platform where users can only see their friends' daily photos after posting their own. Features include camera capture, location tagging, post blurring, likes, comments, and notification reminders.

Time spent: **10** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] User can launch camera to take photo instead of photo library
  - [x] Users can choose between Camera or Photo Library via action sheet
  - [x] Camera opens automatically when navigating to Post screen
- [x] Users can interact with posts via comments (Comment model implemented)
  - [x] Inline comment display (up to 3 comments shown)
  - [x] Inline comment input field below posts
- [x] Posts have a time and location attached to them
  - [x] Location extracted from photo metadata using PHAsset + CLGeocoder
  - [x] Time displayed using custom DateFormatter
- [x] Users are not able to see other users' photos until they upload their own
  - [x] Posts are blurred using UIVisualEffectView
  - [x] Blur is hidden if user's last post was within 24 hours of the post
 
The following **optional** features are implemented:

- [x] User receives notification when it is time to post
  - [x] Permission requested after login
  - [x] 4-hour repeating local notification scheduled
  - [x] Notifications unregistered on logout

The following **additional** features are implemented:

- [x] Like functionality - users can like/unlike posts with heart button
- [x] Like count displayed on each post
- [x] Heart animation on like (scale bounce effect)
- [x] Comment on posts with inline display (up to 3 comments shown)
- [x] Inline comment input below posts
- [x] Edit profile (change username and email)
- [x] Edit post captions (for own posts only)
- [x] Delete own posts (with confirmation)
- [x] Location metadata extraction from photos using GPS data
- [x] Feed limited to 10 most recent posts within last 24 hours
- [x] Pull-to-refresh functionality
- [x] Infinite scroll pagination
- [x] User's lastPostedDate tracked for blur logic

## Video Walkthrough

[Add your Loom video link here]

## Notes

Challenges encountered:
- Implementing the blur reveal logic required careful date comparison between post creation time and user's last post time
- Extracting photo metadata required using PHAsset with PHPickerViewController
- Managing the like state and real-time UI updates required implementing a delegate pattern
- Adding inline comments required dynamic stack view management

## License

    Copyright 2026 Aaryan Panthi

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
