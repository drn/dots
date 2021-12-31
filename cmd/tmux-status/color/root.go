package color

// Color -
type Color string

const (
	// C1 - color 1
	C1 Color = "#[fg=colour236,bg=colour103]"
	// C1_2 - color 1 to 2 transition
	C1_2 = "#[fg=colour103,bg=colour239,nobold,nounderscore,noitalics]"
	// C1_3 - color 1 to 3 transition
	C1_3 = "#[fg=colour103,bg=colour236,nobold,nounderscore,noitalics]"
	// C2 - color 2
	C2 = "#[fg=colour253,bg=colour239]"
	// C2_3 - color 2 to 3 transition
	C2_3 = "#[fg=colour239,bg=colour236,nobold,nounderscore,noitalics]"
	// C3 - color 3
	C3 = "#[fg=colour244,bg=colour236]"
	// C3Bb10 - color 3 with 10% battery not charging
	C3Bb10 = "#[fg=colour160,bg=colour236]"
	// C3Bb20 - color 3 with 20% battery not charging
	C3Bb20 = "#[fg=colour124,bg=colour236]"
	// C3Bc10 - color 3 with 10% battery charging
	C3Bc10 = "#[fg=colour166,bg=colour236]"
	// C3Bc20 - color 3 with 20% battery charging
	C3Bc20 = "#[fg=colour130,bg=colour236]"
	// C3_2 - color 3 to 2 transition
	C3_2 = "#[fg=colour236,bg=colour239,nobold,nounderscore,noitalics]"
	// C3_1 - color 3 to 1 transition
	C3_1 = "#[fg=colour236,bg=colour103,nobold,nounderscore,noitalics]"
)
