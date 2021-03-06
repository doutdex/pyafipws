Attribute VB_Name = "Module1"
' Ejemplo de Uso de Interface COM con Web Service Certificación Electrónica de Granos
' más info en: http://www.sistemasagiles.com.ar/trac/wiki/LiquidacionPrimariaGranos
' 2014 (C) Mariano Reingart <reingart@gmail.com>

Sub Main()
    Dim WSAA As Object, WSLPG As Object
    Dim ok As Boolean
    
    ttl = 2400 ' tiempo de vida en segundos
    cache = "" ' Directorio para archivos temporales (dejar en blanco para usar predeterminado)
    proxy = "" ' usar "usuario:clave@servidor:puerto"

    Certificado = App.Path & "\..\..\reingart.crt"   ' certificado es el firmado por la afip
    ClavePrivada = App.Path & "\..\..\reingart.key"  ' clave privada usada para crear el cert.
        
    Token = ""
    Sign = ""
    
    Set WSAA = CreateObject("WSAA")
    Debug.Print WSAA.InstallDir
    tra = WSAA.CreateTRA("wslpg", ttl)
    Debug.Print tra
    ' Generar el mensaje firmado (CMS)
    cms = WSAA.SignTRA(tra, Certificado, ClavePrivada)
    Debug.Print cms
    
    wsdl = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl" ' homologación
    ok = WSAA.Conectar(cache, wsdl, proxy)
    ta = WSAA.LoginCMS(cms) 'obtener ticket de acceso
    
    Debug.Print ta
    Debug.Print "Token:", WSAA.Token
    Debug.Print "Sign:", WSAA.Sign
    
    ' Crear objeto interface Web Service de Liquidación Primaria de Granos
    Set WSLPG = CreateObject("WSLPG")
    Debug.Print WSLPG.Version
    Debug.Print WSLPG.InstallDir
    ' Setear tocken y sing de autorización (pasos previos)
    WSLPG.Token = WSAA.Token
    WSLPG.Sign = WSAA.Sign
    ' CUIT (debe estar registrado en la AFIP)
    WSLPG.cuit = "20267565393"
    
    ' Conectar al Servicio Web
    ok = WSLPG.Conectar("", "", "") ' homologación
    If Not ok Then
        Debug.Print WSLPG.Traceback
        MsgBox WSLPG.Traceback, vbCritical + vbExclamation, WSLPG.Excepcion
    End If
        
    ' Establecer tipo de certificación a autorizar
    tipo_certificado = "D"      '  cambiar D: deposito, P: planta, R: retiro, T: transf, E: preexistente
        
    ' genero una certificación de ejemplo a autorizar (datos generales de cabecera):
    pto_emision = 99
    nro_orden = 1
    nro_planta = "1"
    nro_ing_bruto_depositario = "20267565393"
    titular_grano = "T"
    cuit_depositante = "20111111112"
    nro_ing_bruto_depositante = "123"
    cuit_corredor = "20222222223"
    cod_grano = 2
    campania = 1314
    datos_adicionales = "Prueba"
    
    ' Establezco los datos de cabecera
    ok = WSLPG.CrearCertificacionCabecera( _
            pto_emision, nro_orden, _
            tipo_certificado, nro_planta, _
            nro_ing_bruto_depositario, _
            titular_grano, _
            cuit_depositante, _
            nro_ing_bruto_depositante, _
            cuit_corredor, _
            cod_grano, campania, _
            datos_adicionales)

    Select Case tipo_certificado
        Case "D", "P"
            ' datos del certificado depósito F1116A:
            descripcion_tipo_grano = "SOJA"
            monto_almacenaje = 1: monto_acarreo = 2
            monto_gastos_generales = 3: monto_zarandeo = 4
            porcentaje_secado_de = 5: porcentaje_secado_a = 6
            monto_secado = 7: monto_por_cada_punto_exceso = 8
            monto_otros = 9: analisis_muestra = 10: nro_boletin = 11
            valor_grado = 1.02: valor_contenido_proteico = 1: valor_factor = 1
            porcentaje_merma_volatil = 15: peso_neto_merma_volatil = 16
            porcentaje_merma_secado = 17: peso_neto_merma_secado = 18
            porcentaje_merma_zarandeo = 19: peso_neto_merma_zarandeo = 20
            peso_neto_certificado = 21: servicios_secado = 22
            servicios_zarandeo = 23: servicios_otros = 24
            servicios_forma_de_pago = 25
            
            ok = WSLPG.AgregarCertificacionPlantaDepositoElevador( _
                    descripcion_tipo_grano, _
                    monto_almacenaje, monto_acarreo, _
                    monto_gastos_generales, monto_zarandeo, _
                    porcentaje_secado_de, porcentaje_secado_a, _
                    monto_secado, monto_por_cada_punto_exceso, _
                    monto_otros, analisis_muestra, nro_boletin, _
                    valor_grado, valor_contenido_proteico, valor_factor, _
                    porcentaje_merma_volatil, peso_neto_merma_volatil, _
                    porcentaje_merma_secado, peso_neto_merma_secado, _
                    porcentaje_merma_zarandeo, peso_neto_merma_zarandeo, _
                    peso_neto_certificado, servicios_secado, _
                    servicios_zarandeo, servicios_otros, _
                    servicios_forma_de_pago _
                    )
        
            descripcion_rubro = "bonif": tipo_rubro = "B":
            porcentaje = 1: valor = 1
            ok = WSLPG.AgregarDetalleMuestraAnalisis( _
                descripcion_rubro, tipo_rubro, porcentaje, valor)
    
            nro_ctg = "123456": nro_carta_porte = 1000:
            porcentaje_secado_humedad = 1: importe_secado = 2:
            peso_neto_merma_secado = 3: tarifa_secado = 4:
            importe_zarandeo = 5: peso_neto_merma_zarandeo = 6:
            tarifa_zarandeo = 7
            ok = WSLPG.AgregarCTG( _
                nro_ctg, nro_carta_porte, _
                porcentaje_secado_humedad, importe_secado, _
                peso_neto_merma_secado, tarifa_secado, _
                importe_zarandeo, peso_neto_merma_zarandeo, _
                tarifa_zarandeo)
    
        Case "R", "T":
            ' establezco datos del certificado retiro/transferencia F1116R/T:
            cuit_receptor = "20400000000": fecha = "2014-11-26"
            nro_carta_porte_a_utilizar = "12345"
            cee_carta_porte_a_utilizar = "123456789012"
            ok = WSLPG.AgregarCertificacionRetiroTransferencia( _
                    cuit_receptor, fecha, _
                    nro_carta_porte_a_utilizar, _
                    cee_carta_porte_a_utilizar)
            ' datos del certificado (los Null no se utilizan por el momento)
            peso_neto = 10000: coe_certificado_deposito = "123456789012"
            tipo_certificado_deposito = Null: nro_certificado_deposito = Null
            cod_localidad_procedencia = Null:  cod_prov_procedencia = Null
            campania = Null: fecha_cierre = Null
            ok = WSLPG.AgregarCertificado( _
                           tipo_certificado_deposito, _
                           nro_certificado_deposito, _
                           peso_neto, _
                           cod_localidad_procedencia, _
                           cod_prov_procedencia, _
                           campania, fecha_cierre, _
                           peso_neto, coe_certificado_deposito _
                            )
            
        Case "E":
            ' establezco datos del certificado preexistente:
            tipo_certificado_deposito_preexistente = 1: ' "R" o "T"
            nro_certificado_deposito_preexistente = "12345"
            cee_certificado_deposito_preexistente = "123456789012"
            fecha_emision_certificado_deposito_preexistente = "2014-11-26"
            peso_neto = 1000
            ok = WSLPG.AgregarCertificacionPreexistente( _
                    tipo_certificado_deposito_preexistente, _
                    nro_certificado_deposito_preexistente, _
                    cee_certificado_deposito_preexistente, _
                    fecha_emision_certificado_deposito_preexistente, _
                    peso_neto)
    
    End Select

    ' Llamo al metodo remoto cgAutorizar:
    
    ok = WSLPG.AutorizarCertificacion()
    
    If ok Then
        ' muestro los resultados devueltos por el webservice:
        
        Debug.Print "COE", WSLPG.COE
        Debug.Print "Fecha", WSLPG.FechaCertificacion
        
        MsgBox "COE: " & WSLPG.COE & vbCrLf, vbInformation, "Autorizar Liquidación:"
        If WSLPG.ErrMsg <> "" Then
            Debug.Print "Errores", WSLPG.ErrMsg
            ' recorro y muestro los errores
            For Each er In WSLPG.Errores
                MsgBox er, vbExclamation, "Error"
            Next
        End If

    Else
        ' muestro el mensaje de error
        Debug.Print WSLPG.Traceback
        Debug.Print WSLPG.XmlRequest
        Debug.Print WSLPG.XmlResponse
        MsgBox WSLPG.Traceback, vbCritical + vbExclamation, WSLPG.Excepcion
    End If
    
End Sub
