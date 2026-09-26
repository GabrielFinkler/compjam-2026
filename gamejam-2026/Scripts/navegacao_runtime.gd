extends NavigationRegion2D
## Monta a malha de navegação dos monstros quando a fase começa, a partir das colisões das
## camadas de tiles do grupo "navegacao" (paredes e móveis). Assim, mexer no mapa pelo editor
## já atualiza os caminhos, sem precisar "assar" a malha na mão.
## Portas ficam de fora de propósito: um monstro pode seguir por uma porta depois que ela abre.

func _ready() -> void:
	bake_navigation_polygon(true)
