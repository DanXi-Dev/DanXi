/*
 *     Copyright (C) 2021  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

enum Stickers {
  dx_angry,
  dx_call,
  dx_cate,
  dx_dying,
  dx_egg,
  dx_fright,
  dx_heart,
  dx_hug,
  dx_overwhelm,
  dx_roll,
  dx_roped,
  dx_sleep,
  dx_swim,
  dx_thrill,
  dx_touch_fish,
  dx_twin,
  dx_kiss,
  dx_onlooker,
  dx_craving,
  dx_caught,
  dx_worn,
  dx_murderous,
  dx_confused,
  dx_like;
}

String? getStickerAssetPath(String stickerName) {
  try {
    Stickers sticker =
        Stickers.values.firstWhere((e) => e.name.toString() == stickerName);
    return "assets/graphics/stickers/${sticker.name}.webp";
  } catch (error) {
    return null;
  }
}
