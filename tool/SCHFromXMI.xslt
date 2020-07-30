<?xml version="1.0" encoding="UTF-8"?>

<!--
	XSLT to collect scopes, patterns and schematrons written in UML Class constraints in an XMI file to create a SCH file
	Modified to also include schematron rules for codelist checking

	Created by B.L. Choy (blchoy.hko@gmail.com).  First created on 31 March 2016.  Last updated on 12 April 2020.

	Tested with the following:
		(1) XMI: Created by EA 12.1 Build 1224 with UML 1.3 (XMI 1.1)
		(2) XSLT processor: Saxon-HE 9.7.0.15N
		(3) Scopes, patterns and schematrons written in UML Class constraint descriptions with the following template:
			Pattern ID: [A string containing a unique pattern ID within the SCH file]
			Description: [A string containing the message to be shown when the assertion returns a false]
			Assertion: [A string containing the assertion to be run]
		(4) WMO Codes Registry entries in Codelist Classes
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:UML="omg.org/UML1.3" exclude-result-prefixes="UML"> 
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:strip-space elements="*"/>

	<xsl:template match="/XMI">

		<xsl:param name="namespace_prefix" select="substring-before(./XMI.content/UML:TaggedValue[@tag='xmlns']/@value,'#')"/>
		<xsl:param name="namespace_uri" select="substring-before(./XMI.content/UML:TaggedValue[@tag='targetNamespace']/@value,'#')"/>

		<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

			<sch:title>Schematron validation</sch:title>

			<!--
				Default namespace(s) to be included
			-->
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'xlink'"/>
				<xsl:with-param name="uri" select="'http://www.w3.org/1999/xlink'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'xsi'"/>
				<xsl:with-param name="uri" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'gml'"/>
				<xsl:with-param name="uri" select="'http://www.opengis.net/gml/3.2'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'aixm'"/>
				<xsl:with-param name="uri" select="'http://www.aixm.aero/schema/5.1.1'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'metce'"/>
				<xsl:with-param name="uri" select="'http://def.wmo.int/metce/2013'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'rdf'"/>
				<xsl:with-param name="uri" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'skos'"/>
				<xsl:with-param name="uri" select="'http://www.w3.org/2004/02/skos/core#'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'reg'"/>
				<xsl:with-param name="uri" select="'http://purl.org/linked-data/registry#'"/>
			</xsl:call-template>
			<!--
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'sf'"/>
				<xsl:with-param name="uri" select="'http://www.opengis.net/sampling/2.0'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'sams'"/>
				<xsl:with-param name="uri" select="'http://www.opengis.net/samplingSpatial/2.0'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'om'"/>
				<xsl:with-param name="uri" select="'http://www.opengis.net/om/2.0'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'opm'"/>
				<xsl:with-param name="uri" select="'http://def.wmo.int/opm/2013'"/>
			</xsl:call-template>
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="'collect'"/>
				<xsl:with-param name="uri" select="'http://def.wmo.int/collect/2014'"/>
			</xsl:call-template>
			-->

			<!-- Add namespace and namespace prefix of the package as defined in the UML model -->
			<xsl:call-template name="namespace">
				<xsl:with-param name="prefix" select="$namespace_prefix"/>
				<xsl:with-param name="uri" select="$namespace_uri"/>
			</xsl:call-template>

			<!-- Add rules from UML model -->
			<xsl:apply-templates select="@*|node()">
				<xsl:with-param name="prefix" select="$namespace_prefix"/>
			</xsl:apply-templates>

			<!-- Add rule for nilReason -->
			<xsl:call-template name="nilReason">
				<xsl:with-param name="prefix" select="$namespace_prefix"/>
			</xsl:call-template>

			<!-- Add rule for extension -->
			<xsl:call-template name="extension">
				<xsl:with-param name="prefix" select="$namespace_prefix"/>
			</xsl:call-template>

		</sch:schema>

	</xsl:template>
	
	<xsl:template name="namespace">
		<xsl:param name="prefix"/>
		<xsl:param name="uri"/>
        	<xsl:element name='sch:ns'>
			<xsl:attribute name="prefix">
				<xsl:value-of select="$prefix"/>
			</xsl:attribute>
			<xsl:attribute name="uri">
				<xsl:value-of select="$uri"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- Extract and create schematron rules from UML model -->	
	<xsl:template match="//UML:Class/UML:ModelElement.constraint/UML:Constraint">
		<xsl:param name="prefix"/>
		<xsl:call-template name="pattern">
			<xsl:with-param name="prefix" select="$prefix"/>
			<xsl:with-param name="className" select="../../@name"/>
			<xsl:with-param name="inputString" select="./UML:ModelElement.taggedValue/UML:TaggedValue[@tag='description']/@value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="pattern">
		<xsl:param name="prefix"/>
		<xsl:param name="className"/>
		<xsl:param name="inputString"/>
		<xsl:param name="id" select="'No ID'"/>
		<xsl:param name="description" select="'No description'"/>
		<xsl:param name="assertion" select="'No assertion'"/>
		<xsl:param name="index" select="1"/>
		<xsl:variable name="tokenString" select="tokenize($inputString,'&#xA;')"/>
		<xsl:variable name="index_max" select="3"/>
		<xsl:choose>
			<xsl:when test="$index &lt;= $index_max">
				<xsl:if test="lower-case(normalize-space(substring-before($tokenString[$index],':'))) = 'pattern id'">
					<xsl:call-template name="pattern">
						<xsl:with-param name="prefix" select="$prefix"/>
						<xsl:with-param name="className" select="$className"/>
						<xsl:with-param name="inputString" select="$inputString"/>
						<xsl:with-param name="id" select="normalize-space(substring-after($tokenString[$index],':'))"/>
						<xsl:with-param name="description" select="$description"/>
						<xsl:with-param name="assertion" select="$assertion"/>
						<xsl:with-param name="index" select="$index + 1"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:if test="lower-case(normalize-space(substring-before($tokenString[$index],':'))) = 'description'">
					<xsl:call-template name="pattern">
						<xsl:with-param name="prefix" select="$prefix"/>
						<xsl:with-param name="className" select="$className"/>
						<xsl:with-param name="inputString" select="$inputString"/>
						<xsl:with-param name="id" select="$id"/>
						<xsl:with-param name="description" select="normalize-space(substring-after($tokenString[$index],':'))"/>
						<xsl:with-param name="assertion" select="$assertion"/>
						<xsl:with-param name="index" select="$index + 1"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:if test="lower-case(normalize-space(substring-before($tokenString[$index],':'))) = 'assertion'">
					<xsl:call-template name="pattern">
						<xsl:with-param name="prefix" select="$prefix"/>
						<xsl:with-param name="className" select="$className"/>
						<xsl:with-param name="inputString" select="$inputString"/>
						<xsl:with-param name="id" select="$id"/>
						<xsl:with-param name="description" select="$description"/>
						<xsl:with-param name="assertion" select="normalize-space(substring-after($tokenString[$index],':'))"/>
						<xsl:with-param name="index" select="$index + 1"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name='sch:pattern'>
					<xsl:attribute name="id">
						<xsl:value-of select="$id"/>
					</xsl:attribute>
					<xsl:element name='sch:rule'>
						<xsl:attribute name="context">
							<xsl:if test="not(//UML:Class[@name=$className]/@isAbstract = 'true' or //UML:Class[@name=$className]/UML:ModelElement.stereotype/UML:Stereotype/@name = 'enumeration' or //UML:Class[@name=$className]/UML:ModelElement.stereotype/UML:Stereotype/@name = 'codeList')">
								<xsl:value-of select="concat('//',$prefix,':',$className)"/>
							</xsl:if>
							<xsl:apply-templates select="//UML:Generalization/UML:ModelElement.taggedValue/UML:TaggedValue[@tag='ea_targetName' and @value=$className]" mode="findSrcName">
								<xsl:with-param name="prefix" select="$prefix"/>
								<xsl:with-param name="parentIsAbstract" select="not(//UML:Class[@name=$className]/@isAbstract = 'true' or //UML:Class[@name=$className]/UML:ModelElement.stereotype/UML:Stereotype/@name = 'enumeration' or //UML:Class[@name=$className]/UML:ModelElement.stereotype/UML:Stereotype/@name = 'codeList')"/>
							</xsl:apply-templates>
						</xsl:attribute>
						<xsl:element name='sch:assert'>
							<xsl:attribute name="test">
								<xsl:value-of select="$assertion"/>
							</xsl:attribute>
							<xsl:value-of select="concat($id,': ',$description)"/>
						</xsl:element>
					</xsl:element>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*|node()" mode="findSrcName">
		<xsl:param name="prefix"/>
		<xsl:param name="parentIsAbstract"/>
		<xsl:variable name="sourceClassName" select="../UML:TaggedValue[@tag='ea_sourceName']/@value"/>
		<xsl:if test="$parentIsAbstract or number(position()) &gt; 1">
			<xsl:value-of select="'|'"/>
		</xsl:if>
		<xsl:if test="//UML:Class[@name=$sourceClassName]/@isAbstract = 'false'">
			<xsl:value-of select="concat('//',$prefix,':',$sourceClassName)"/>
		</xsl:if>
		<xsl:apply-templates select="//UML:Generalization/UML:ModelElement.taggedValue/UML:TaggedValue[@tag='ea_targetName' and @value=$sourceClassName]" mode="findSrcName">
			<xsl:with-param name="prefix" select="$prefix"/>
			<xsl:with-param name="parentIsAbstract" select="//UML:Class[@name=$sourceClassName]/@isAbstract = 'false'"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Add schematron rules to check the codelist elements -->
	<xsl:template match="//UML:Class/UML:ModelElement.stereotype/UML:Stereotype[@name='codeList']">
		<xsl:param name="prefix"/>
		<xsl:param name="className" select="../../@name"/>
		<xsl:param name="xmi.id" select="../../@xmi.id"/>
		<xsl:param name="inputString" select="//UML:TaggedValue[@tag='vocabulary' and @modelElement=$xmi.id]/@value"/>
		<xsl:param name="tokenString" select="tokenize($inputString,'#')"/>
		<xsl:param name="codeList" select="normalize-space($tokenString[1])"/>
		<!-- Code list as target of an association -->
		<xsl:for-each select="//UML:Association/UML:ModelElement.taggedValue/UML:TaggedValue[@tag='ea_targetName' and @value=$className]">
			<xsl:call-template name="pattern-codeList">
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="codeList" select="$codeList"/>
				<xsl:with-param name="selfName" select="substring(current()/../UML:TaggedValue[@tag='rt']/@value,2)"/>
				<xsl:with-param name="parentName" select="current()/../UML:TaggedValue[@tag='ea_sourceName']/@value"/>
				<xsl:with-param name="packageName" select="//UML:Class[@name=current()/../UML:TaggedValue[@tag='ea_sourceName']/@value]/UML:ModelElement.taggedValue/UML:TaggedValue[@tag='package_name']/@value"/>
			</xsl:call-template>
		</xsl:for-each>
		<!-- Code list as an attribute -->
		<xsl:for-each select="//UML:Class/UML:Classifier.feature/UML:Attribute/UML:ModelElement.taggedValue/UML:TaggedValue[@tag='type' and @value=$className]">
			<xsl:call-template name="pattern-codeList">
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="codeList" select="$codeList"/>
				<xsl:with-param name="selfName" select="current()/../../@name"/>
				<xsl:with-param name="parentName" select="current()/../../../../@name"/>
				<xsl:with-param name="packageName" select="current()/../../../../UML:ModelElement.taggedValue/UML:TaggedValue[@tag='package_name']/@value"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="pattern-codeList">
		<xsl:param name="prefix"/>
		<xsl:param name="codeList"/>
		<xsl:param name="selfName"/>
		<xsl:param name="parentName"/>
		<xsl:param name="packageName"/>
		<xsl:element name='sch:pattern'>
			<xsl:attribute name="id">
				<xsl:value-of select="concat(replace(replace($packageName,'/','_'),' ',''),'.',$parentName,'.',$selfName)"/>
			</xsl:attribute>
			<xsl:element name='sch:rule'>
				<xsl:attribute name="context">
					<xsl:value-of select="concat('//',$prefix,':',$parentName,'/',$prefix,':',$selfName)"/>
				</xsl:attribute>
				<xsl:element name='sch:assert'>
					<xsl:attribute name="test">
						<xsl:value-of select="concat('@xlink:href = document(''',replace(substring($codeList,8),'/','-'),'.rdf'')/rdf:RDF/*/skos:member/*/@*[local-name()=''about''] or @nilReason')"/>
					</xsl:attribute>
					<xsl:value-of select="concat($parentName,'/',$prefix,':',$selfName,' elements should be a member of ',$codeList)"/>
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<!-- Add a schematron rule to check the nilReason attributes -->
	<xsl:template name="nilReason">
		<xsl:param name="prefix"/>
		<xsl:element name='sch:pattern'>
			<xsl:attribute name="id">
				<xsl:value-of select="'IWXXM.nilReasonCheck'"/>
			</xsl:attribute>
			<xsl:element name='sch:rule'>
				<xsl:attribute name="context">
					<xsl:value-of select="concat('//',$prefix,':*')"/>
				</xsl:attribute>
				<xsl:element name='sch:assert'>
					<xsl:attribute name="test">
						<xsl:value-of select="'( if( exists(@nilReason) ) then( @nilReason = document(''codes.wmo.int-common-nil.rdf'')/rdf:RDF/*/skos:member/*/@*[local-name()=''about''] ) else( true() ) )'"/>
					</xsl:attribute>
					<xsl:value-of select="string('IWXXM.nilReasonCheck: nilReason attributes should be a member of http://codes.wmo.int/common/nil')"/>
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<!-- Add a schematron rule to check the extension elements -->
	<xsl:template name="extension">
		<xsl:param name="prefix"/>
		<xsl:element name='sch:pattern'>
			<xsl:attribute name="id">
				<xsl:value-of select="'IWXXM.ExtensionAlwaysLast'"/>
			</xsl:attribute>
			<xsl:element name='sch:rule'>
				<xsl:attribute name="context">
					<xsl:value-of select="concat('//',$prefix,':extension')"/>
				</xsl:attribute>
				<xsl:element name='sch:assert'>
					<xsl:attribute name="test">
						<xsl:value-of select="concat('following-sibling::*[1][self::',$prefix,':extension] or not(following-sibling::*)')"/>
					</xsl:attribute>
					<xsl:value-of select="string('IWXXM.ExtensionAlwaysLast: Extension elements should be the last elements in their parents')"/>
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<xsl:template match="text()|@*"/>

</xsl:stylesheet>
