This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test01.lama -o test | grep -v 'section .note.GNU-stack'
  /usr/bin/ld: warning: printf.o: missing .note.GNU-stack section implies executable stack
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  [1]
  $ ./test
  Set internal structure: MNode (63, 1, 0, MNode (31, 1, 0, MNode (15, 1, 0, MNode (7, 1, 0, MNode (3, 1, 0, MNode (1, 1, 0, MNode (0, 1, 0, 0, 0), MNode (2, 1, 0, 0, 0)), MNode (5, 1, 0, MNode (4, 1, 0, 0, 0), MNode (6, 1, 0, 0, 0))), MNode (11, 1, 0, MNode (9, 1, 0, MNode (8, 1, 0, 0, 0), MNode (10, 1, 0, 0, 0)), MNode (13, 1, 0, MNode (12, 1, 0, 0, 0), MNode (14, 1, 0, 0, 0)))), MNode (23, 1, 0, MNode (19, 1, 0, MNode (17, 1, 0, MNode (16, 1, 0, 0, 0), MNode (18, 1, 0, 0, 0)), MNode (21, 1, 0, MNode (20, 1, 0, 0, 0), MNode (22, 1, 0, 0, 0))), MNode (27, 1, 0, MNode (25, 1, 0, MNode (24, 1, 0, 0, 0), MNode (26, 1, 0, 0, 0)), MNode (29, 1, 0, MNode (28, 1, 0, 0, 0), MNode (30, 1, 0, 0, 0))))), MNode (47, 1, 0, MNode (39, 1, 0, MNode (35, 1, 0, MNode (33, 1, 0, MNode (32, 1, 0, 0, 0), MNode (34, 1, 0, 0, 0)), MNode (37, 1, 0, MNode (36, 1, 0, 0, 0), MNode (38, 1, 0, 0, 0))), MNode (43, 1, 0, MNode (41, 1, 0, MNode (40, 1, 0, 0, 0), MNode (42, 1, 0, 0, 0)), MNode (45, 1, 0, MNode (44, 1, 0, 0, 0), MNode (46, 1, 0, 0, 0)))), MNode (55, 1, 0, MNode (51, 1, 0, MNode (49, 1, 0, MNode (48, 1, 0, 0, 0), MNode (50, 1, 0, 0, 0)), MNode (53, 1, 0, MNode (52, 1, 0, 0, 0), MNode (54, 1, 0, 0, 0))), MNode (59, 1, 0, MNode (57, 1, 0, MNode (56, 1, 0, 0, 0), MNode (58, 1, 0, 0, 0)), MNode (61, 1, 0, MNode (60, 1, 0, 0, 0), MNode (62, 1, 0, 0, 0)))))), MNode (79, 1, -1, MNode (71, 1, 0, MNode (67, 1, 0, MNode (65, 1, 0, MNode (64, 1, 0, 0, 0), MNode (66, 1, 0, 0, 0)), MNode (69, 1, 0, MNode (68, 1, 0, 0, 0), MNode (70, 1, 0, 0, 0))), MNode (75, 1, 0, MNode (73, 1, 0, MNode (72, 1, 0, 0, 0), MNode (74, 1, 0, 0, 0)), MNode (77, 1, 0, MNode (76, 1, 0, 0, 0), MNode (78, 1, 0, 0, 0)))), MNode (87, 1, -1, MNode (83, 1, 0, MNode (81, 1, 0, MNode (80, 1, 0, 0, 0), MNode (82, 1, 0, 0, 0)), MNode (85, 1, 0, MNode (84, 1, 0, 0, 0), MNode (86, 1, 0, 0, 0))), MNode (95, 1, 0, MNode (91, 1, 0, MNode (89, 1, 0, MNode (88, 1, 0, 0, 0), MNode (90, 1, 0, 0, 0)), MNode (93, 1, 0, MNode (92, 1, 0, 0, 0), MNode (94, 1, 0, 0, 0))), MNode (97, 1, -1, MNode (96, 1, 0, 0, 0), MNode (98, 1, -1, 0, MNode (99, 1, 0, 0, 0)))))))
  Set elements: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99}
  Testing 0   => 1
  Testing 100 => 0
  Testing 1   => 1
  Testing 101 => 0
  Testing 2   => 1
  Testing 102 => 0
  Testing 3   => 1
  Testing 103 => 0
  Testing 4   => 1
  Testing 104 => 0
  Testing 5   => 1
  Testing 105 => 0
  Testing 6   => 1
  Testing 106 => 0
  Testing 7   => 1
  Testing 107 => 0
  Testing 8   => 1
  Testing 108 => 0
  Testing 9   => 1
  Testing 109 => 0
  Testing 10  => 1
  Testing 110 => 0
  Testing 11  => 1
  Testing 111 => 0
  Testing 12  => 1
  Testing 112 => 0
  Testing 13  => 1
  Testing 113 => 0
  Testing 14  => 1
  Testing 114 => 0
  Testing 15  => 1
  Testing 115 => 0
  Testing 16  => 1
  Testing 116 => 0
  Testing 17  => 1
  Testing 117 => 0
  Testing 18  => 1
  Testing 118 => 0
  Testing 19  => 1
  Testing 119 => 0
  Testing 20  => 1
  Testing 120 => 0
  Testing 21  => 1
  Testing 121 => 0
  Testing 22  => 1
  Testing 122 => 0
  Testing 23  => 1
  Testing 123 => 0
  Testing 24  => 1
  Testing 124 => 0
  Testing 25  => 1
  Testing 125 => 0
  Testing 26  => 1
  Testing 126 => 0
  Testing 27  => 1
  Testing 127 => 0
  Testing 28  => 1
  Testing 128 => 0
  Testing 29  => 1
  Testing 129 => 0
  Testing 30  => 1
  Testing 130 => 0
  Testing 31  => 1
  Testing 131 => 0
  Testing 32  => 1
  Testing 132 => 0
  Testing 33  => 1
  Testing 133 => 0
  Testing 34  => 1
  Testing 134 => 0
  Testing 35  => 1
  Testing 135 => 0
  Testing 36  => 1
  Testing 136 => 0
  Testing 37  => 1
  Testing 137 => 0
  Testing 38  => 1
  Testing 138 => 0
  Testing 39  => 1
  Testing 139 => 0
  Testing 40  => 1
  Testing 140 => 0
  Testing 41  => 1
  Testing 141 => 0
  Testing 42  => 1
  Testing 142 => 0
  Testing 43  => 1
  Testing 143 => 0
  Testing 44  => 1
  Testing 144 => 0
  Testing 45  => 1
  Testing 145 => 0
  Testing 46  => 1
  Testing 146 => 0
  Testing 47  => 1
  Testing 147 => 0
  Testing 48  => 1
  Testing 148 => 0
  Testing 49  => 1
  Testing 149 => 0
  Testing 50  => 1
  Testing 150 => 0
  Testing 51  => 1
  Testing 151 => 0
  Testing 52  => 1
  Testing 152 => 0
  Testing 53  => 1
  Testing 153 => 0
  Testing 54  => 1
  Testing 154 => 0
  Testing 55  => 1
  Testing 155 => 0
  Testing 56  => 1
  Testing 156 => 0
  Testing 57  => 1
  Testing 157 => 0
  Testing 58  => 1
  Testing 158 => 0
  Testing 59  => 1
  Testing 159 => 0
  Testing 60  => 1
  Testing 160 => 0
  Testing 61  => 1
  Testing 161 => 0
  Testing 62  => 1
  Testing 162 => 0
  Testing 63  => 1
  Testing 163 => 0
  Testing 64  => 1
  Testing 164 => 0
  Testing 65  => 1
  Testing 165 => 0
  Testing 66  => 1
  Testing 166 => 0
  Testing 67  => 1
  Testing 167 => 0
  Testing 68  => 1
  Testing 168 => 0
  Testing 69  => 1
  Testing 169 => 0
  Testing 70  => 1
  Testing 170 => 0
  Testing 71  => 1
  Testing 171 => 0
  Testing 72  => 1
  Testing 172 => 0
  Testing 73  => 1
  Testing 173 => 0
  Testing 74  => 1
  Testing 174 => 0
  Testing 75  => 1
  Testing 175 => 0
  Testing 76  => 1
  Testing 176 => 0
  Testing 77  => 1
  Testing 177 => 0
  Testing 78  => 1
  Testing 178 => 0
  Testing 79  => 1
  Testing 179 => 0
  Testing 80  => 1
  Testing 180 => 0
  Testing 81  => 1
  Testing 181 => 0
  Testing 82  => 1
  Testing 182 => 0
  Testing 83  => 1
  Testing 183 => 0
  Testing 84  => 1
  Testing 184 => 0
  Testing 85  => 1
  Testing 185 => 0
  Testing 86  => 1
  Testing 186 => 0
  Testing 87  => 1
  Testing 187 => 0
  Testing 88  => 1
  Testing 188 => 0
  Testing 89  => 1
  Testing 189 => 0
  Testing 90  => 1
  Testing 190 => 0
  Testing 91  => 1
  Testing 191 => 0
  Testing 92  => 1
  Testing 192 => 0
  Testing 93  => 1
  Testing 193 => 0
  Testing 94  => 1
  Testing 194 => 0
  Testing 95  => 1
  Testing 195 => 0
  Testing 96  => 1
  Testing 196 => 0
  Testing 97  => 1
  Testing 197 => 0
  Testing 98  => 1
  Testing 198 => 0
  Testing 99  => 1
  Testing 199 => 0
  Set internal structure: MNode (63, 0, 0, MNode (31, 1, 0, MNode (15, 1, 0, MNode (7, 1, 0, MNode (3, 1, 0, MNode (1, 1, 0, MNode (0, 1, 0, 0, 0), MNode (2, 1, 0, 0, 0)), MNode (5, 1, 0, MNode (4, 1, 0, 0, 0), MNode (6, 1, 0, 0, 0))), MNode (11, 1, 0, MNode (9, 1, 0, MNode (8, 1, 0, 0, 0), MNode (10, 1, 0, 0, 0)), MNode (13, 1, 0, MNode (12, 1, 0, 0, 0), MNode (14, 1, 0, 0, 0)))), MNode (23, 1, 0, MNode (19, 1, 0, MNode (17, 1, 0, MNode (16, 1, 0, 0, 0), MNode (18, 1, 0, 0, 0)), MNode (21, 1, 0, MNode (20, 1, 0, 0, 0), MNode (22, 1, 0, 0, 0))), MNode (27, 1, 0, MNode (25, 1, 0, MNode (24, 1, 0, 0, 0), MNode (26, 1, 0, 0, 0)), MNode (29, 1, 0, MNode (28, 1, 0, 0, 0), MNode (30, 1, 0, 0, 0))))), MNode (47, 1, 0, MNode (39, 1, 0, MNode (35, 1, 0, MNode (33, 1, 0, MNode (32, 1, 0, 0, 0), MNode (34, 1, 0, 0, 0)), MNode (37, 1, 0, MNode (36, 1, 0, 0, 0), MNode (38, 1, 0, 0, 0))), MNode (43, 1, 0, MNode (41, 1, 0, MNode (40, 1, 0, 0, 0), MNode (42, 1, 0, 0, 0)), MNode (45, 1, 0, MNode (44, 1, 0, 0, 0), MNode (46, 1, 0, 0, 0)))), MNode (55, 0, 0, MNode (51, 0, 0, MNode (49, 1, 0, MNode (48, 1, 0, 0, 0), MNode (50, 0, 0, 0, 0)), MNode (53, 0, 0, MNode (52, 0, 0, 0, 0), MNode (54, 0, 0, 0, 0))), MNode (59, 0, 0, MNode (57, 0, 0, MNode (56, 0, 0, 0, 0), MNode (58, 0, 0, 0, 0)), MNode (61, 0, 0, MNode (60, 0, 0, 0, 0), MNode (62, 0, 0, 0, 0)))))), MNode (79, 0, -1, MNode (71, 0, 0, MNode (67, 0, 0, MNode (65, 0, 0, MNode (64, 0, 0, 0, 0), MNode (66, 0, 0, 0, 0)), MNode (69, 0, 0, MNode (68, 0, 0, 0, 0), MNode (70, 0, 0, 0, 0))), MNode (75, 0, 0, MNode (73, 0, 0, MNode (72, 0, 0, 0, 0), MNode (74, 0, 0, 0, 0)), MNode (77, 0, 0, MNode (76, 0, 0, 0, 0), MNode (78, 0, 0, 0, 0)))), MNode (87, 0, -1, MNode (83, 0, 0, MNode (81, 0, 0, MNode (80, 0, 0, 0, 0), MNode (82, 0, 0, 0, 0)), MNode (85, 0, 0, MNode (84, 0, 0, 0, 0), MNode (86, 0, 0, 0, 0))), MNode (95, 0, 0, MNode (91, 0, 0, MNode (89, 0, 0, MNode (88, 0, 0, 0, 0), MNode (90, 0, 0, 0, 0)), MNode (93, 0, 0, MNode (92, 0, 0, 0, 0), MNode (94, 0, 0, 0, 0))), MNode (97, 0, -1, MNode (96, 0, 0, 0, 0), MNode (98, 0, -1, 0, MNode (99, 0, 0, 0, 0)))))))
  Set elements: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49}
  Testing 0   => 1
  Testing 1   => 1
  Testing 2   => 1
  Testing 3   => 1
  Testing 4   => 1
  Testing 5   => 1
  Testing 6   => 1
  Testing 7   => 1
  Testing 8   => 1
  Testing 9   => 1
  Testing 10  => 1
  Testing 11  => 1
  Testing 12  => 1
  Testing 13  => 1
  Testing 14  => 1
  Testing 15  => 1
  Testing 16  => 1
  Testing 17  => 1
  Testing 18  => 1
  Testing 19  => 1
  Testing 20  => 1
  Testing 21  => 1
  Testing 22  => 1
  Testing 23  => 1
  Testing 24  => 1
  Testing 25  => 1
  Testing 26  => 1
  Testing 27  => 1
  Testing 28  => 1
  Testing 29  => 1
  Testing 30  => 1
  Testing 31  => 1
  Testing 32  => 1
  Testing 33  => 1
  Testing 34  => 1
  Testing 35  => 1
  Testing 36  => 1
  Testing 37  => 1
  Testing 38  => 1
  Testing 39  => 1
  Testing 40  => 1
  Testing 41  => 1
  Testing 42  => 1
  Testing 43  => 1
  Testing 44  => 1
  Testing 45  => 1
  Testing 46  => 1
  Testing 47  => 1
  Testing 48  => 1
  Testing 49  => 1
  Testing 50  => 0
  Testing 51  => 0
  Testing 52  => 0
  Testing 53  => 0
  Testing 54  => 0
  Testing 55  => 0
  Testing 56  => 0
  Testing 57  => 0
  Testing 58  => 0
  Testing 59  => 0
  Testing 60  => 0
  Testing 61  => 0
  Testing 62  => 0
  Testing 63  => 0
  Testing 64  => 0
  Testing 65  => 0
  Testing 66  => 0
  Testing 67  => 0
  Testing 68  => 0
  Testing 69  => 0
  Testing 70  => 0
  Testing 71  => 0
  Testing 72  => 0
  Testing 73  => 0
  Testing 74  => 0
  Testing 75  => 0
  Testing 76  => 0
  Testing 77  => 0
  Testing 78  => 0
  Testing 79  => 0
  Testing 80  => 0
  Testing 81  => 0
  Testing 82  => 0
  Testing 83  => 0
  Testing 84  => 0
  Testing 85  => 0
  Testing 86  => 0
  Testing 87  => 0
  Testing 88  => 0
  Testing 89  => 0
  Testing 90  => 0
  Testing 91  => 0
  Testing 92  => 0
  Testing 93  => 0
  Testing 94  => 0
  Testing 95  => 0
  Testing 96  => 0
  Testing 97  => 0
  Testing 98  => 0
  Testing 99  => 0
  List set: MNode (2, 1, -1, MNode (1, 1, 0, 0, 0), MNode (4, 1, 0, MNode (3, 1, 0, 0, 0), MNode (5, 1, 0, 0, 0)))
  Set union: MNode (4, 1, -1, MNode (2, 1, 0, MNode (1, 1, 0, 0, 0), MNode (3, 1, 0, 0, 0)), MNode (33, 1, 0, MNode (11, 1, 0, MNode (5, 1, 0, 0, 0), MNode (22, 1, 0, 0, 0)), MNode (44, 1, -1, 0, MNode (55, 1, 0, 0, 0))))
  Elements: {1, 2, 3, 4, 5, 11, 22, 33, 44, 55}
  Set difference: MNode (4, 1, -1, MNode (2, 1, 0, MNode (1, 0, 0, 0, 0), MNode (3, 0, 0, 0, 0)), MNode (33, 1, 0, MNode (11, 1, 0, MNode (5, 0, 0, 0, 0), MNode (22, 0, 0, 0, 0)), MNode (44, 0, -1, 0, MNode (55, 1, 0, 0, 0))))
  Elements: {2, 4, 11, 33, 55}
