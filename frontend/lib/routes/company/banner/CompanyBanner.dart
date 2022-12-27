import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/company/EditCompanyForm.dart';
import 'package:frontend/routes/company/banner/CompanyStatusDropdownButton.dart';
import 'package:provider/provider.dart';

class CompanyBanner extends StatelessWidget {
  final Company company;
  final void Function(int, BuildContext) statusChangeCallback;
  final void Function(BuildContext, Company?) onEdit;

  const CompanyBanner(
      {Key? key,
      required this.company,
      required this.statusChangeCallback,
      required this.onEdit})
      : super(key: key);

  void _editCompanyModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditCompanyForm(company: company, onEdit: this.onEdit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    bool isEditable = Provider.of<EventNotifier>(context).isLatest;
    Participation? part = company.participations!
        .firstWhereOrNull((element) => element.event == event);
    ParticipationStatus companyStatus =
        part != null ? part.status : ParticipationStatus.NO_STATUS;
    double lum = 0.2;
    var matrix = <double>[
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Greyscale matrix. Lum represents level of luminosity
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        return Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  colorFilter: Provider.of<ThemeNotifier>(context).isDark
                      ? ColorFilter.matrix(matrix)
                      : null,
                  image: AssetImage('assets/banner_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: small ? 4 : 20, vertical: small ? 5 : 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(8.0, 8.0, small ? 8 : 20.0, 8.0),
                      child: SizedBox(
                        height: small ? 100 : 150,
                        width: small ? 100 : 150,
                        child: Hero(
                          tag: company.id + event.toString(),
                          child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: small ? 2 : 4,
                                  color: STATUSCOLOR[companyStatus]!,
                                ),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(300.0),
                                child: Image.network(
                                    company.companyImages.internal,
                                    fit: BoxFit.cover, errorBuilder:
                                        (BuildContext context, Object exception,
                                            StackTrace? stackTrace) {
                                  return Image.asset('assets/noImage.png');
                                }),
                              )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(small ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: Theme.of(context).textTheme.headline5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isEditable)
                              CompanyStatusDropdownButton(
                                companyStatus: companyStatus,
                                statusChangeCallback: statusChangeCallback,
                                companyId: company.id,
                              ),
                            if (!isEditable)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: STATUSCOLOR[companyStatus]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(STATUSSTRING[companyStatus]!),
                                  ),
                                ),
                              ),
                            //TODO define subscribe behaviour
                            ElevatedButton(
                                onPressed: () => print('zona'),
                                child: Text('+ Subscribe'))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _editCompanyModal(context);
              },
            )
          ],
        );
      },
    );
  }
}
