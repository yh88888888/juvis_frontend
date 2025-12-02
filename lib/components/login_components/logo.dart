import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:juvis_faciliry/size.dart';

class Logo extends StatelessWidget {
  final String title;

  const Logo(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset("assets/juviss.svg", height: 110, width: 110),
        SizedBox(height: small_gap),
        Text(
          title,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
