import 'package:flutter/material.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/page-title-app-bar.dart';
import '../../features/home/models/animal-category.dart';
import 'widgets/animal-species-section.dart';

const Color _unselectedTextColor = Color(0xFF9B9B9B);

class AnimalTypeSelectPage extends StatefulWidget {
  const AnimalTypeSelectPage({super.key});

  @override
  State<AnimalTypeSelectPage> createState() => _AnimalTypeSelectPageState();
}

class _AnimalTypeSelectPageState extends State<AnimalTypeSelectPage> {
  int _selectedIndex = 0;
  String? _selectedGroupName;
  String? _selectedSpecies;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PageTitleAppBar(title: '동물종류 선택'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(15.s, 21.s, 15.s, 43.s),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 228.s,
                  padding: EdgeInsets.only(
                    left: 31.s,
                    right: 31.s,
                    top: 14.s,
                    bottom: 14.91.s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.868.s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 3.s,
                        spreadRadius: 0.2.s,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 13.s),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 140.s) / 3;
                          return Wrap(
                            spacing: 70.s,
                            runSpacing: 11.s,
                            children: animalCategories
                                .asMap()
                                .entries
                                .map(
                                  (e) => GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedIndex = e.key;
                                      _selectedGroupName = null;
                                      _selectedSpecies = null;
                                    }),
                                    child: SizedBox(
                                      width: itemWidth,
                                      child: _AnimalCategoryItem(
                                        name: e.value.name,
                                        iconPath: e.value.iconPath,
                                        isSelected: _selectedIndex == e.key,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.s),
                AnimalSpeciesSection(
                  categoryIndex: _selectedIndex,
                  onSpeciesSelected: (groupName, species) => setState(() {
                    _selectedGroupName = groupName;
                    _selectedSpecies = species;
                  }),
                  onSave: () {
                    Navigator.of(context).pop(<String, String>{
                      'category': _selectedGroupName ?? '',
                      'species': _selectedSpecies ?? '',
                    });
                  },
                ),
                SizedBox(height: 43.s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalCategoryItem extends StatelessWidget {
  final String name;
  final String iconPath;
  final bool isSelected;

  const _AnimalCategoryItem({
    required this.name,
    required this.iconPath,
    required this.isSelected,
  });

  String get _resolvedIconPath =>
      isSelected ? iconPath : iconPath.replaceFirst('be-', 'un-');

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? AppColors.main : _unselectedTextColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56.s,
          height: 56.s,
          child: Image.asset(
            _resolvedIconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 56.s,
                height: 56.s,
                decoration: const BoxDecoration(
                  color: AppColors.main,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 35),
              );
            },
          ),
        ),
        SizedBox(height: 6.s),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontFamily: AppFonts.family,
            fontSize: 11.564,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.231,
          ),
        ),
      ],
    );
  }
}
