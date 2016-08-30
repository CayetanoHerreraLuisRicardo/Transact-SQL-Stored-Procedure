--verifica si existe un SP con el nombre de "spPedVenta" si si lo elimina
if exists (select * from sysobjects where id = object_id('spPedVenta') and sysstat & 0xf = 4)
	drop procedure spPedVenta
GO
--Como mandar a llamar al SP
--EXEC spPedVenta '002','2240','03','01','GRA ','','','',0,'',0,0,'',''
CREATE PROCEDURE [dbo].[spPedVenta]
	@ClaveAlmacen		varchar(5) = '',
	@CodCliente			varchar(15)= '',
	@CodZona			varchar(10)= '',
	@CodAgente			varchar(10)= '',
	@CodTipoCliente		varchar(10)= '',
	@CodRuta			varchar(10)= '',
	@CodRepartidor		varchar(10)= '',
	@Clase1				varchar(15)= '',
	@RutaVuelta			smallint   = 0,
	@Serie				varchar(2) = '',
	@NumPedidoIni		int		   = 0,
	@NumPedidoFin		int        = 0,
	@FechaIni			varchar(25)='',
	@FechaFin			varchar(25)='',
	@Surtido			char(1)=''
AS
/*
**	Nombre		spPedVenta
**
** 	Proposito: 	Reportes de Clientes | Relación de Pedidos de Venta
** 	Parametros:	
**
**	Retorna:	0 Exito, 
**
**
**	Autor creacion: 	LRCH
**	Fecha creacion:		30/Oct/2015
**	Fecha ultima mod:	02/Oct/2015
*/

/*
*********************MODIFICACIONES***************************************
**
**
**************************************************************************
*/
--Con esto le decimos al servidor que no queremos que nos devuelva le número de filas afectadas 
SET NOCOUNT ON
--declaracion de variables a utilizar el sl SP
DECLARE @ConsultaSQL varchar(1500)		--Para almacenar la consulta base
DECLARE @CondicionSQL varchar(500)		--Para guardar la condicion dinaminca
--inicializando variables
SET @ConsultaSQL = ''
SET @CondicionSQL = ''
--convertimos las fechas de entrada (string a datetime)
SELECT @FechaIni = CONVERT(DateTime,@FechaIni)
SELECT @FechaFin = CONVERT(DateTime,@FechaFin)

--iniciamos a validar los datos de entrada (si se pasaron valores para hacer la condicion dinámica)
IF @ClaveAlmacen <>''	SET @CondicionSQL += ' AND '''+@ClaveAlmacen+''' = PedCab.ClaveAlmacen ' 
IF @CodCliente <>''		SET @CondicionSQL += ' AND '''+@CodCliente+''' = PedCab.CodCliente ' 
IF @CodZona <>''		SET @CondicionSQL += ' AND '''+@CodZona+''' = PedCab.CodZona ' 
IF @CodAgente<>''		SET @CondicionSQL += ' AND '''+@CodAgente+''' = PedCab.CodAgente ' 
IF @CodTipoCliente <>''	SET @CondicionSQL += ' AND '''+@CodTipoCliente+''' = PedCab.CodTipoCliente ' 
IF @CodRuta <>''		SET @CondicionSQL += ' AND '''+@CodRuta+''' = PedCab.CodRuta ' 
IF @CodRepartidor <>''	SET @CondicionSQL += ' AND '''+@CodRepartidor+''' = PedCab.CodRepartidor ' 
IF @Clase1 <>''			SET @CondicionSQL += ' AND '''+@Clase1+''' = PedCab.Clase1 ' 
IF @RutaVuelta <> 0		SET @CondicionSQL += ' AND '''+CAST(@RutaVuelta  AS VARCHAR)+''' = PedCab.RutaVuelta ' 
IF @Serie <>''			SET @CondicionSQL += ' AND '''+@Clase1+''' = PedCab.@Serie ' 
IF @NumPedidoIni <> @NumPedidoFin	SET @CondicionSQL += ' AND (PedCab.NumPedido BETWEEN '''+CAST(@NumPedidoIni  AS INT)+''' AND '''+CAST(@NumPedidoFin  AS INT)+''') '
IF @FechaIni <>''		SET @CondicionSQL += ' AND DATEDIFF(dd, '''+@FechaIni+''', PedCab.FechaExpedicion) >= 0 '
IF @FechaFin <>''		SET @CondicionSQL += ' AND DATEDIFF(dd, '''+@FechaFin+''', PedCab.FechaExpedicion) <= 0 '
IF @Serie <>''			SET @CondicionSQL += ' AND '''+@Serie+''' = PedCab.@Serie'
IF @Surtido <>'T'		SET @CondicionSQL += ' AND '''+@Surtido+''' = PedCab.Surtido'

--La consulta base sera siempre la misma(estática) ... ojo agregando al final la condiciín  "WHERE 1=1" esto con el fin de concatenar 
--cualquier condicion que se cumpla P.E: si se cumple unicamente la 3ra condicion la condicion final seria .... WHERE 1=1 AND 'IKDKSH' = PedCab.CodZona 
SET @ConsultaSQL ='SELECT PedCab.idDocumento, PedCab.Serie, PedCab.NumPedido, PedCab.CodCliente, PedCab.NomFiscal, PedCab.RFC, PedCab.Calle, PedCab.NumExterior, PedCab.NumInterior, PedCab.Localidad, PedCab.CodEstado, PedCab.Pais, PedCab.DiasCredito, PedCab.CodZona, PedCab.CodAgente, PedCab.FechaExpedicion, PedCab.FechaVencimiento, PedCab.FechaSurtido, PedCab.TotalNetoSinImp, PedCab.TotalDocumento, PedCab.TotalImpuesto1, PedCab.Usuario, PedCab.Observaciones, PedCab.DiasCredito, '+
    ' PedDet.Partida, PedDet.ClaveArticulo, PedDet.Descripcion, PedDet.PrecioNeto, PedDet.Cantidad, PedDet.ImportePartida, PedDet.CantidadAdicional1, PedDet.SurtidoCantidad,'+
    ' CatClientes.Telefono,'+
    ' Medidas.Descripcion'+
	' FROM PedCab'+
	' JOIN PedDet ON PedCab.idMovimiento = PedDet.idMovimiento'+
	' JOIN CatClientes ON PedCab.CodCliente = CatClientes.CodCliente'+
	' LEFT JOIN Medidas ON PedDet.UnMedida = Medidas.Unidad WHERE 1=1 '
--condición (opcional) si se generó una conidición, entonces concatena la consulta base(@ConsultaSQL) + la condicion generada (@CondicionSQL)
--o simplemente eliminar la condición (IF @CondicionSQL <> '') y concatenanarlas directamente dara el mismo resultado :)
IF @CondicionSQL <> ''	SET @ConsultaSQL+=@CondicionSQL
--La sentencia (EXEC) permite ejecutar una cadena de caracteres que representa una sentencia SQL ==> que es la consulta que hemos generado
EXEC(@ConsultaSQL)