// Animation fade-in
import 'package:flutter/material.dart';

Animation<double> getAnimation(BuildContext context) {
  return Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: ModalRoute.of(context)?.animation ??
          const AlwaysStoppedAnimation(1.0),
      curve: Curves.easeIn,
    ),
  );
}
