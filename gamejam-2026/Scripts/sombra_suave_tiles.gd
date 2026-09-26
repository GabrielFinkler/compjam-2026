extends TileMapLayer
## Camada de objetos (móveis, caixas...) com sombra de contato fixa: uma silhueta escura um
## pouco abaixo de cada objeto, pra ele parecer "em pé" no chão. Sai do polígono de colisão,
## então só o que bloqueia o jogador ganha sombra: sombra = não dá pra atravessar.
## Tiles que já bloqueiam a luz sozinhos (paredes) ficam de fora.

@export_range(0.0, 1.0) var forca_sombra: float = 0.5 ## Quão escura é a sombra (0 = nenhuma, 1 = preta)
@export var deslocamento: Vector2 = Vector2(1, 3) ## Pra onde a sombra "cai" em relação ao objeto, em pixels
@export var borda_suave: float = 1.0 ## Pixels de borda mais clara em volta da sombra (0 = borda seca)

var _poligonos: Array[PackedVector2Array] = []

func _ready() -> void:
	for celula in get_used_cells():
		var dados := get_cell_tile_data(celula)
		if dados == null or _tem_oclusor(dados):
			continue
		var alternativo := get_cell_alternative_tile(celula)
		var espelha_h := (alternativo & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
		var espelha_v := (alternativo & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
		var transpoe := (alternativo & TileSetAtlasSource.TRANSFORM_TRANSPOSE) != 0
		var centro := map_to_local(celula)
		for camada in tile_set.get_physics_layers_count():
			for i in dados.get_collision_polygons_count(camada):
				var pontos := _transformar(dados.get_collision_polygon_points(camada, i), espelha_h, espelha_v, transpoe)
				if pontos.size() < 3:
					continue
				for j in pontos.size():
					pontos[j] += centro
				_poligonos.append(_sombra_de(pontos))

	# Desenha num CanvasGroup pra sombras vizinhas não se somarem e ficarem mais escuras
	# onde se cruzam. Fica logo abaixo da camada: por cima do chão, por baixo dos objetos.
	var grupo := CanvasGroup.new()
	grupo.z_index = -1
	grupo.self_modulate.a = forca_sombra
	add_child(grupo)
	var desenho := Node2D.new()
	desenho.draw.connect(_desenhar_sombras.bind(desenho))
	grupo.add_child(desenho)

# O objeto "arrastado" até o deslocamento: a sombra fica colada nele, sem vão no meio
func _sombra_de(poligono: PackedVector2Array) -> PackedVector2Array:
	var pontos := PackedVector2Array(poligono)
	for p in poligono:
		pontos.append(p + deslocamento)
	var contorno := Geometry2D.convex_hull(pontos)
	if contorno.size() > 1 and contorno[0].is_equal_approx(contorno[contorno.size() - 1]):
		contorno.remove_at(contorno.size() - 1) # convex_hull repete o primeiro ponto no fim
	return contorno

func _desenhar_sombras(desenho: Node2D) -> void:
	for sombra in _poligonos:
		if sombra.size() < 3:
			continue
		# Borda mais clara primeiro, miolo por cima: o contorno fica suave
		if borda_suave > 0.0:
			# A sombra é convexa, então crescer ela nunca gera furos
			for borda in Geometry2D.offset_polygon(sombra, borda_suave, Geometry2D.JOIN_ROUND):
				desenho.draw_colored_polygon(borda, Color(0, 0, 0, 0.5))
		desenho.draw_colored_polygon(sombra, Color.BLACK)

func _tem_oclusor(dados: TileData) -> bool:
	for camada in tile_set.get_occlusion_layers_count():
		if dados.get_occluder_polygons_count(camada) > 0:
			return true
	return false

# Mesma ordem que o TileMap usa pra tiles espelhados/girados
func _transformar(pontos: PackedVector2Array, espelha_h: bool, espelha_v: bool, transpoe: bool) -> PackedVector2Array:
	var resultado := PackedVector2Array()
	for p in pontos:
		if transpoe:
			p = Vector2(p.y, p.x)
		if espelha_h:
			p.x = -p.x
		if espelha_v:
			p.y = -p.y
		resultado.append(p)
	return resultado
