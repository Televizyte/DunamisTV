/// KEEP THESE URLS EXACTLY AS YOU SENT THEM.

class Links {
  // 1) Dunamis TV HLS live link (m3u8)
  static const String dunamisHls = 'https://atechgroupuk.site/DTV.m3u8';

  // 2) YouTube Live fallback (playlist or channel live URL)
  static const String youtubeLiveFallback =
      'https://youtube.com/playlist?list=PLsFcFNo2Ku199zMhBztn8Kf5L_q5NSkdG&si=t8Q_1hIly-uqHgg8';

  // 3) WatchSOD Today YouTube (playlist)
  static const String watchSodToday =
      'https://youtube.com/playlist?list=PLsFcFNo2Ku1_ntUPoiEhY-uNR3GsSi2X4&si=z8mOg6vYOfctx9CO';

  // 4) ReadSOD website link
  static const String readSod =
      'https://dunamisgospel.org/category/seed-of-destiny/';

  // 5) Other Christian TV channels (10 to start; you provided 3)
  static const otherChannels = <ChannelLink>[
    ChannelLink(
      name: 'Salvation TV',
      url: 'https://iframe.viewmedia.tv/?channel=017',
    ),
    ChannelLink(
      name: 'Dove TV',
      url: 'https://iframe.viewmedia.tv/?channel=093',
    ),
    ChannelLink(
      name: 'COZA TV',
      url: 'https://iframe.viewmedia.tv/?channel=097',
    ),
  ];

  // 6) Videos (YouTube links)
  static const videos = <ChannelLink>[
    ChannelLink(
      name: 'COMMANDING THE DAY PRAYER BROADCAST',
      url: 'https://www.youtube.com/watch?v=h5dBu2pf99s&list=PLsFcFNo2Ku18Yev7LYduuw7h6nql2PPf7&pp=gAQB',
    ),
    ChannelLink(
      name: 'HEALING AND DELIVERANCE SERVICE',
      url: 'https://www.youtube.com/watch?v=vkjf-wBj9UA&list=PLsFcFNo2Ku1-7z6_ztR6Zs-jKElGZhVY_&pp=gAQB',
    ),
    ChannelLink(
      name: 'TESTIMONIES AT DUNAMIS',
      url: 'https://www.youtube.com/watch?v=zBEidHApzf4&list=PLsFcFNo2Ku1_roRwhIPQeRzHsnaVvuHBA&pp=gAQB',
    ),
  ];
}

class ChannelLink {
  final String name;
  final String url;
  const ChannelLink({required this.name, required this.url});
}
